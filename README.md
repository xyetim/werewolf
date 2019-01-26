# Werewolf

## Development setup

### Environment configure

- Ruby

```
$ ruby -v
ruby 2.3.3p222
 ```

- Rails

```
$ rails -v
Rails 5.0.7
```

- Bundler

```
$ bundle -v
Bundler version 1.15.4
```

### Setup

- Provision

```
$ cd {project_dir}
$ bundle install --path=vendor/bundle
```

- Database

setup your database config in config/database.yml

default is `mysql -hlocalhost:3306 -uroot` (no pass)

* Database migration

```
$ cd {project_dir}
$ bundle exec rake db:create
$ bundle exec rake db:migrate
$ bundle exec rake db:seed
```

* Start development programe

```
$ cd {project_dir}
$ bundle exec rails server
(then access http://localhost:3000 using any browser)
```

### Audio

https://ai.baidu.com/tech/speech/tts
