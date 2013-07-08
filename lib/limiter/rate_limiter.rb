# -*- encoding : utf-8 -*-
module Limiter
  class RateLimiter < Base
    GET_TTL = 20.minutes
    MAX_GET_NUM = 1000
    
    POST_TTL = 5.seconds
    MAX_POST_NUM = 20

    attr_reader :max_get_num
    attr_reader :max_post_num
    attr_reader :get_ttl
    attr_reader :post_ttl

    def initialize(app, options = {})
      super
      @max_get_num = options[:max_get_num] || MAX_GET_NUM
      @max_post_num = options[:max_post_num] || MAX_POST_NUM
      @post_ttl = options[:post_ttl] || POST_TTL
      @get_ttl = options[:get_ttl] || GET_TTL
    end

    def visit_counter
      @visit_counter ||= options[:visit_counter]
    end

    def allowed?(request)
      common_allowed = super
      return common_allowed unless common_allowed.nil?

      client_id = client_identifier(request)
      post_count = read_and_incr_post_num(request, client_id)
      get_count = read_and_incr_get_num(request, client_id)
      
      if (get_count > max_get_num || post_count > max_post_num)
        limit_callback.call(client_id) if limit_callback
        false
      else
        true
      end
    end

    def client_identifier(request)
      # 61.135.163.4 -> 61.135.163.0
      super(request).sub(/\.\d+$/, ".0")
    end

    private

    def read_and_incr_post_num(request, client_id)
      if request.post?
        post_count = visit_counter.count(client_id, "POST")
        visit_counter.incr(client_id, "POST", post_ttl)
        return post_count
      end
      return 0
    end

    def read_and_incr_get_num(request, client_id)
      get_count = visit_counter.count(client_id, "GET")
      visit_counter.incr(client_id, "GET", get_ttl)
      return get_count
    end
   
  end
end
