# -*- encoding : utf-8 -*-
module Limiter
  class BlackList
    def initialize(cache_store)
      @cache_store = cache_store
    end

    def list
      @cache_store.smembers(key)
    end

    def add(ip)
      @cache_store.sadd(key, ip)
    end

    def remove(ip)
      @cache_store.srem(key, ip)
    end

    def member?(ip)
      @cache_store.sismember(key, ip)
    end

    def key
      "limiter/black_list"
    end
  end
end
