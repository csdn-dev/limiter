# -*- encoding : utf-8 -*-
module Limiter
  class VisitCounter
    def initialize(cache_store)
      @cache_store = cache_store
    end

    def remove(ip, method)
      @cache_store.del cache_key(ip, method)
    end

    def incr(ip, method, ttl)
      @cache_store.multi do
        @cache_store.incr cache_key(ip, method)
        @cache_store.expire(cache_key(ip, method), ttl)
      end
    end

    def count(ip, method)
      @cache_store.get(cache_key(ip, method)).to_i
    end

    def set(ip, method, ttl, num)
      @cache_store.setex(cache_key(ip, method), ttl, num)
    end

    def remove_both(ip)
      remove ip, 'GET'
      remove ip, 'POST'
    end

    private
    def cache_key(ip, method)
      ['limiter/vc', ip, method].join('/')
    end
  end
end
