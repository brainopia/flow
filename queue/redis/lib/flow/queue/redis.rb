require 'flow/queue'
require 'redis'

# TODO: batch mode via lua script with brpoplpush and subsequent rpoplpush
# or by bundling more logical tasks in one physical task
# also benchmark in comparison to sidekiq
# add reliable pull
class Flow::Queue::Redis < Flow::Queue
  attr_accessor :connection
  Flow::Queue::PROVIDERS[:redis] = self

  def initialize(*)
    super
    @name = "flow-#{name}"
  end

  def push_raw(message)
    client.lpush name, message
  end

  def pull_raw
    client.brpop(name).last
  end

  def clear
    client.del name
  end

  def count
    client.llen name
  end

  private

  def client
    Thread.current[:flow_redis] ||= begin
      ::Redis.new(connection || {}).instance_eval do
        def synchronize
          yield @client
        end
        self
      end
    end
  end
end
