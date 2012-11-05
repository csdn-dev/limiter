# Limiter

Rack middleware for rate-limiting incoming HTTP requests with black_list and white_list support.

## Installation

Add this line to your application's Gemfile:

    gem 'limiter', :git => "git://github.com/csdn-dev/limiter.git"

And then execute:

    $ bundle

## Usage

```ruby
# config/initializers/limiter.rb
require File.expand_path("../redis", __FILE__)
Rails.configuration.app_middleware.insert_before(Rack::MethodOverride,
                                                 Limiter::RateLimiter,
                                                 :max_get_num => 1000,
                                                 :get_ttl => 20.minutes,

                                                 :max_post_num => 20,
                                                 :post_ttl => 5.seconds,

                                                 :black_list => Limiter::BlackList.new($redis),
                                                 :white_list => Limiter::WhiteList.new($redis),
                                                 :allow_path => Rails.env.development? ? /^\/(assets|human_validations|simple_captcha)/ :
                                                                                         /^\/(human_validations|simple_captcha)/,
                                                 :message => "<a href='/human_validations/new'>我不是机器人</a>",
                                                 :visit_counter => Limiter::VisitCounter.new($redis)
                                                )
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
