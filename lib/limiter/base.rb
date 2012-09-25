# -*- encoding : utf-8 -*-
# This is the base class for rate limiter implementations.
#
# @example Defining a rate limiter subclass
#   class MyLimiter < Limiter::Base
#     def allowed?(request)
#       # TODO: custom logic goes here
#     end
#   end
#
module Limiter
  class Base
    attr_reader :app
    attr_reader :options
    attr_reader :white_list
    attr_reader :black_list
    attr_reader :allow_path
    attr_reader :allow_agent

    ##
    # @param  [#call]                    app
    # @param  [Hash{Symbol => Object}]   options
    # @option options [BlackList]        :black_list  (BlackList.new($redis))
    # @option options [WhiteList]        :white_list  (WhiteList.new($redis))
    # @option options [String/Regexp]    :allow_path  ("/human_test")
    # @option options [Regex]            :allow_agent (/agent1|agent2/)
    # @option options [Integer]          :code        (403)
    # @option options [String]           :message     ("Rate Limit Exceeded")
    
    def initialize(app, options = {})
      @black_list  = options[:black_list]
      @white_list  = options[:white_list]
      @allow_path  = options[:allow_path]
      @allow_agent = options[:allow_agent]
      @app, @options = app, options
    end

    ##
    # @param  [Hash{String => String}] env
    # @return [Array(Integer, Hash, #each)]
    # @see    http://rack.rubyforge.org/doc/SPEC.html
    def call(env)
      request = Rack::Request.new(env)
      allowed?(request) ? app.call(env) : rate_limit_exceeded
    end

    ##
    # Returns `false` if the rate limit has been exceeded for the given
    # `request`, or `true` otherwise.
    #
    # Override this method in subclasses that implement custom rate limiter
    # strategies.
    #
    # @param  [Rack::Request] request
    # @return [Boolean]
    def allowed?(request)
      case
      when allow_path?(request)  then true
      when allow_agent?(request) then true
      when whitelisted?(request) then true
      when blacklisted?(request) then false
      else nil # override in subclasses
      end
    end

    def whitelisted?(request)
      white_list.member?(client_identifier(request))
    end

    def blacklisted?(request)
      black_list.member?(client_identifier(request))
    end

    def allow_path?(request)
      if allow_path.is_a?(Regexp)
        request.path =~ allow_path
      else
        request.path == allow_path
      end
    end

    def allow_agent?(request)
      return false unless allow_agent
      request.user_agent.to_s =~ allow_agent
    end

    protected

    ##
    # @param  [Rack::Request] request
    # @return [String]
    def client_identifier(request)
      request.ip.to_s
    end

    ##
    # @param  [Rack::Request] request
    # @return [Float]
    def request_start_time(request)
      case
      when request.env.has_key?('HTTP_X_REQUEST_START')
        request.env['HTTP_X_REQUEST_START'].to_f / 1000
      else
        Time.now.to_f
      end
    end

    ##
    # Outputs a `Rate Limit Exceeded` error.
    #
    # @return [Array(Integer, Hash, #each)]
    def rate_limit_exceeded
      headers = respond_to?(:retry_after) ? {'Retry-After' => retry_after.to_f.ceil.to_s} : {}
      http_error(options[:code] || 403, options[:message], headers)
    end

    ##
    # Outputs an HTTP `4xx` or `5xx` response.
    #
    # @param  [Integer]                code
    # @param  [String, #to_s]          message
    # @param  [Hash{String => String}] headers
    # @return [Array(Integer, Hash, #each)]
    def http_error(code, message = nil, headers = {})
      body = if message 
               [message]
             else
               [http_status(code) + " : Rate Limit Exceeded\n"]
             end
      [code, {'Content-Type' => 'text/html; charset=utf-8'}.merge(headers), body]
    end

    ##
    # Returns the standard HTTP status message for the given status `code`.
    #
    # @param  [Integer] code
    # @return [String]
    def http_status(code)
      [code, Rack::Utils::HTTP_STATUS_CODES[code]].join(' ')
    end
  end
end
