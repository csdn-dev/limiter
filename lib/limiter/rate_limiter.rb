# -*- encoding : utf-8 -*-
module Limiter
  class RateLimiter < Base
    GET_TTL = 20.minutes
    MAX_GET_NUM = 1000
    
    POST_TTL = 5.seconds
    MAX_POST_NUM = 20

    def initialize(app, options = {})
      super
    end

    def visit_counter
      @visit_counter ||= options[:visit_counter]
    end

    def allowed?(request)
      common_allowed = super
      return true if common_allowed == true
      return false if common_allowed == false

      client_id = client_identifier(request)
      post_count = read_and_incr_post_num(request, client_id)
      get_count = read_and_incr_get_num(request, client_id)
      
      return false if (get_count > MAX_GET_NUM || post_count > MAX_POST_NUM)
      return true
    end

    def client_identifier(request)
      # 61.135.163.4 -> 61.135.163.0
      request.ip.to_s.sub(/\.\d+$/, ".0")
    end

    private

    def read_and_incr_post_num(request, client_id)
      if request.post?
        post_count = visit_counter.count(client_id, "POST")
        visit_counter.incr(client_id, "POST", POST_TTL)
        return post_count
      end
      return 0
    end

    def read_and_incr_get_num(request, client_id)
      get_count = visit_counter.count(client_id, "GET")
      visit_counter.incr(client_id, "GET", GET_TTL)
      return get_count
    end
   
  end
end
