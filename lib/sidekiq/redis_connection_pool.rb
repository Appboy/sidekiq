# frozen_string_literal: true

require "connection_pool"
require "redis"

module Sidekiq
  # This is a Braze-added class that will annotate exceptions with the name/url of the redis instance that the exception
  # occured with.
  class RedisConnectionPool < ConnectionPool
    # We override #initialize so that we can assign a name and URL to the ConnectionPool. That way, if we have
    # connection errors, we can roll them up by name/location.
    def initialize(name, url, options = {}, &block)
      super(options, &block)
      @name = name
      @url = url
    end

    # We override #with so that we can catch connection-related errors.
    def with(options = {})
      super
    rescue Redis::BaseConnectionError, Timeout::Error => e
      begin
        e.instance_variable_set(:@redis_url, @url)
        e.instance_variable_set(:@redis_type, @name)
      rescue
        # ignored
      end
      raise e
    end
  end
end
