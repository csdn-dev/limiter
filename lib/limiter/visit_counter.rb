# -*- encoding : utf-8 -*-
module Limiter
  class VisitCounter
    def initialize(cache_store)
      @cache_store = cache_store
    end

    def remove(ip, method)
      cache_key = [key, ip, method].join("/")
      @cache_store.del(cache_key)
    end

    def incr(ip, method, ttl)
      cache_key = [key, ip, method].join("/")
      @cache_store.multi do
        @cache_store.incr(cache_key)
        @cache_store.expire(cache_key, ttl)
      end
    end

    def count(ip, method)
      cache_key = [key, ip, method].join("/")
      @cache_store.get(cache_key).to_i
    end

    def set(ip, method, ttl, num)
      cache_key = [key, ip, method].join("/")
      @cache_store.setex(cache_key, ttl, num)
    end

    def key
      "limiter/vc"
    end
  end
end
