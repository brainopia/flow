require 'flow/queue'
require 'redis'

# TODO: batch mode via lua script with brpoplpush and subsequent rpoplpush
# or by bundling more logical tasks in one physical task
# also benchmark in comparison to sidekiq
module Flow::Queue::Redis
  extend self, Flow::Queue
  attr_accessor :connection

  PENDING_QUEUE = 'flow-pending'
  Flow::Queue::PROVIDERS[:redis] = self

  def push_raw(queue, message)
    client.lpush redis_name(queue), message
  end

  def pull_raw(queue)
    client.brpoplpush redis_name(queue), pending_queue
  end

  def clear(queue)
    client.del redis_name(queue)
  end

  def handle_once(queue)
    message = pull queue
    action = Flow::Queue::ACTIONS.fetch message[:action]
    action.propagate_next message[:type], message[:data]
  end

  private

  def redis_name(queue)
    "flow-#{queue}"
  end

  def pending_queue
    redis_name 'pending'
  end

  def client
    Thread.current[:flow_queue_redis] ||= begin
      Redis.new(connection || {}).instance_eval do
        def synchronize
          yield @client
        end
        self
      end
    end
  end
end
