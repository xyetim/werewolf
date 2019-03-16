class GameEngin
  def reset
    Status.new.save
    History.clear
    Role.clear
    Player.reset
    Vote.clear
    UserVote.clear
    Bid.clear
  end

  def sit(user, pos)
    return :failed_not_turn unless Status.find_current.init?

    player = Player.find_by_key pos
    return :failed_seat_not_available if player.user_id

    old_player = Player.find_by_user user
    if old_player
      old_player.assign! nil
      old_player.save
    end

    player.assign! user
    player.save
    :success
  end

  def deal(method = :random)
    players = Player.find_all
    players.each do |p|
      return :failed_empty_seat unless p.user
    end

    status = Status.find_current
    return :failed_game_not_over unless status.over

    status.check_role!
    status.save
    History.clear
    Role.clear
    Vote.clear
    UserVote.clear

    if method == :bid
      roles = Role.deal_roles_by_bid players
      Bid.clear
    else
      # default
      # random deal
      roles = Role.deal_roles players
    end
    Player.set_roles roles

    :success
  end

  def deal_by_bid
    deal(:bid)
  end

  def check_role(user)
    return :failed_not_turn if Status.find_current.init?

    p = Player.find_by_user user
    return :failed_not_seat unless p
    return :failed_no_role unless p.role

    p.role.name
  end

  def start
    status = Status.find_current
    return :failed_not_turn unless status.check_role? || status.turn == :day

    Player.find_all.each do |p|
      return :failed_empty_seat unless p.name
      return :failed_no_role unless p.role
    end

    status.over = false
    status.save

    # init new round data
    new_history = History.new status.round + 1
    new_history.save

    :success
  end

  def skip_turn?
    status = Status.find_current
    return false if %i[init check_role day].include? status.turn

    players = Player.find_all_alive
    p = players.select { |pp| pp.role.skill_turn == status.turn }.first
    p.nil?
  end

  def skill_active(user)
    status = Status.find_current
    return :failed_not_turn if status.init? || status.check_role?

    p = Player.find_by_user user
    return :failed_not_seat unless p
    return :failed_no_role unless p.role
    return :failed_not_turn unless status.turn == p.role.skill_turn
    return "failed_not_#{p.role.skill_timing}".to_sym unless p.status == p.role.skill_timing

    p.role.prepare_skill
  end

  def skill(user, target)
    can_use_skill = self.skill_active user
    return can_use_skill if can_use_skill.to_s.start_with?('failed')

    player = Player.find_by_user user
    res = player.role.use_skill target

    res
  end

  def start_vote(desc, target_pos, voter_pos)
    # vote can only be started in day
    status = Status.find_current
    return :failed_not_turn unless status.turn == :day
    return :failed_vote_has_started unless status.voting == 0

    # set status to vote
    UserVote.clear

    vote = Vote.new desc
    players_pos = Player.find_all_alive.map(&:pos)
    vote.targets = target_pos.nil? || target_pos.empty? ? players_pos : target_pos.map(&:to_i)
    vote.voters = voter_pos.nil? || voter_pos.empty? ? players_pos : voter_pos.map(&:to_i)
    vote.save

    status.voting = vote.ts
    status.save

    { target_pos: vote.targets, voter_pos: vote.voters }
  end

  def vote(user, target)
    # only can vote in day
    status = Status.find_current
    return :failed_not_turn unless status.turn == :day
    return :failed_vote_not_started if status.voting == 0

    vote = Vote.find_by_key status.voting
    player = Player.find_by_user user
    return :failed_not_voter unless player.status == :alive && vote.voters.include?(player.pos)

    user_vote = UserVote.find_by_key player.pos
    return :failed_has_voted if user_vote

    user_vote = UserVote.new player.pos, (target || 0).to_i
    user_vote.save
  end

  def stop_vote
    status = Status.find_current
    return :failed_not_turn unless status.turn == :day
    return :failed_vote_not_started if status.voting == 0

    vote = Vote.find_by_key status.voting
    vote.votes_info = UserVote.find_all
    vote.save

    status.voting = 0
    status.save

    vote.to_msg
  end

  def throw(pos)
    # check current turn is day
    status = Status.find_current
    return :failed_not_turn unless status.turn == :day

    history = History.find_by_key status.round
    pos.each do |p|
      # check players already dead
      player = Player.find_by_key p
      return :failed_target_dead unless player.status == :alive

      # throw out
      player.die!
      player.save

      # update history
      history.dead_in_day.push player.pos
    end
    history.save
    :success
  end

  def bid_roles(user, prices)
    return :failed_negative_price if prices.values.any? { |p| p < 0 }

    total_price = prices.values.reduce(:+)
    user = User.find(user.id)
    user.with_lock do
      return :failed_insufficient_balance if total_price > user.coin

      bid = Bid.find_by_key user.id
      return :failed_already_bid if bid

      bid = Bid.new user.id, prices
      user.coin -= total_price
      user.save!
      bid.save
    end
    :success
  end

  def cancel_bid_roles(user)
    user = User.find(user.id)
    user.with_lock do
      bid = Bid.find_by_key user.id
      return :failed_not_yet_bid unless bid

      user.coin += bid.prices.values.reduce(:+)
      bid.destroy
      user.save!
    end
    :success
  end

  def add_coin_all_users(coin)
    Player.find_all.each do |p|
      user = User.find(p.user.id)
      user.with_lock do
        user.coin += coin
        user.save!
      end
    end
    :success
  end

  def reset_coin_all_users
    # clear bid cache also
    Player.find_all.each do |p|
      user = User.find(p.user.id)
      user.with_lock do
        bid = Bid.find_by_key user.id
        user.coin = 0
        bid&.destroy
        user.save!
      end
    end
    Bid.clear
    :success
  end

  def check_over
    setting = Setting.current

    # get god, villager, wolf cnt
    cnt = { god: 0, villager: 0, wolf: 0 }
    must_kill_alive = false
    Player.find_all.each do |p|
      next unless p.status == :alive
      next if p.role.side_to_check_win.nil?

      cnt[p.role.side_to_check_win] += 1
      must_kill_alive = true if p.role.name == setting.must_kill
    end

    status = Status.find_current
    res = if cnt[:wolf] == 0
            :wolf_lose
          elsif (setting.kill_side? && (cnt[:god] * cnt[:villager]) == 0 && !must_kill_alive) ||
                (setting.kill_all? && cnt[:god] + cnt[:villager] == 0) ||
                (setting.kill_god? && cnt[:god] == 0)
            :wolf_win
          else
            :not_over
          end

    game_over res unless res == :not_over
    res
  end

  def game_over(res)
    Player.find_all.each do |p|
      p.user.results.create role: p.role.name, win: p.role.win?(res)
    end

    status = Status.find_current
    status.over = true
    status.save
  end
end
