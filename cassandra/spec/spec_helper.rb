require 'flow/cassandra'
require 'flow/queue/redis'
require 'support/propagate_helpers'

def Flow.default
  new.cassandra_keyspace(:flow).apply do |it|
    ENV['VERBOSE'] ? it.logger(STDOUT) : it
  end
end

class Flow::Cassandra::Router
  def local_queues
    all_queues
  end
end

Cassandra::Mapper.schema = { keyspaces: [:flow] }
Cassandra::Mapper.env    = :test
Cassandra::Mapper.force_migrate

RSpec.configure do |config|
  config.include PropagateHelpers

  config.before do
    stub_const 'Flow::Queue::ACTIONS_BY_NAME', {}
    Flow::Cassandra::ROUTERS.values.each do |router|
      router.local_queues.each do |queue|
        Flow::Queue::Redis.new(queue).clear
      end
    end

    Cassandra::Mapper.clear!
    Cassandra::Mapper.instances.each do |it|
      it.config.dsl.reset_callbacks!
    end
  end
end
