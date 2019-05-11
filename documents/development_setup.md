# 开发版安装

## 环境配置

基础环境检验,如未安装Ruby,建议新手先安装rvm或rbenv等Ruby管理工具再进行环境部署,可以减少入坑次数，老司机请飘过
```

- Ruby

```
$ ruby -v
ruby version 2.3.3p222
 ```

- Gem

```
$ gem -v
Gem version 2.6.14
```

- Rails

```
$ rails -v
Rails version 5.0.7
```

- Bundler

```
$ bundle -v
Bundler version 2.0.1
```
------------------------------------------------------
* 1.如果 /{项目路径}/Gemfile 文件内某一行有如下行内容:
    '# gem 'therubyracer', platforms: :ruby'
* 则修改为(去掉'#')：
    '  gem 'therubyracer', platforms: :ruby'  
* 2.然后终端执行命令,自动安装依赖与缺少的模块:
  $ bundle install
* 或者跳过步骤1和2,直接在终端执行以下命令:
  $ gem install therubyracer
------------------------------------------------------
```

### 安装

- 初始化

```
$ cd /{项目路径}/
$ bundle install --path=vendor/bundle
```

- 数据库配置

按你数据库的设置填写 /{项目路径}/config/database.yml

* 例如 mysql 当前设置在终端能成功连接的命令为： `mysql -hlocalhost -P3306 -uroot -p` (密码为空)
* database.yml


* 数据库迁移

```
$ cd /{项目路径}/
$ bundle exec rake db:create RAILS_ENV=production   *## 创建对应环境的数据库
$ bundle exec rake db:migrate RAILS_ENV=production  *## 执行迁移数据库
$ bundle exec rake db:seed RAILS_ENV=production     *## 执行 /{项目路径}/db/seeds.rb 数据库脚本
```

* 启动开发版程序

```
$ cd /{项目路径}/
$ bundle exec rails server -b 0.0.0.0 -p 3000 (-b=-bind,绑定用于访问的主机IP)
(用任意浏览器访问 http://{主机IP}:3000)
```

* 启动正式版程序

```
$ cd /{项目路径}/
$ bundle exec rails server -b 0.0.0.0 -p 3000 -e production (-e=-environment,三种环境名称选其一 test || development || production)
(用任意浏览器访问 http://{主机IP}:3000)
```

### 语音发声

https://ai.baidu.com/tech/speech/tts
* 普通女生，语速4，语调4
* 度逍遥(情感男声) 发音咬字较普通女生更清晰


### 游戏规则

名称|含义|技能|描述
:----:|:----:|:----:|:----:
augur|占卜师|Stargaze|夜晚指定一人，狼只能在被指定者及其左右两人中落刀
chief_wolf|白狼王|Destruct|自爆狼枪(必须自爆才可使用)
ghost_rider|恶灵骑士|(被动)反伤|每晚与狼人一起睁眼共同杀人，无法死在夜晚，不能自爆，反伤
god|神抽象基类|-|-
half|混血儿|Link|混血儿与混血对象阵营相同，全程无刀
hidden_wolf|隐狼|有狼队友返回队友数量，无队友则自杀|无狼刀，与狼队互不相认，狼队只剩隐狼时狼队失败，预言家，熊，狐狸，骑士等角色均不能认定其为狼
hunter|猎人|Shoot|-
idiot|白痴|-|公投出局时表明身份，从此无投票权但有发言机会，狼人无需刀翻牌的白痴即可胜利
knight|骑士|Battle|白天投票前翻牌单挑，对方是狼人，狼死，直接入夜，否则骑士死，投票继续
long_wolf|大灰狼|KillMore|与狼队互知身份但不能互通信息，每晚单独睁眼，可额外击杀，全场使用一次且第一夜不可使用，女巫看不见大灰狼刀法，可自爆
lord_wolf|狼王|Shoot|狼枪，毒死、自爆、殉情不开枪
magician|魔术师|Exchange|神，夜间先手行动，交换两人号码牌，整局每个号码牌只能被交换一次
normal_wolf|普狼|-|-
psychic|通灵师|PsychicCheck|查看具体身份
role|角色抽象基类|-|-
savior|守卫|Guard|同守同救死？
seer|预言家|Check|验阵营
villager|普通村民|-|-
witch|女巫|Prescribe|不可一夜双药
wolf|狼人基类|Kill|-


请认真阅读目录下的文档

