require 'flow/cassandra'
require 'flow/queue/redis'
require 'support/propagate_helpers'

def Flow.default
  new.cassandra_keyspace(:flow).apply do |it|
    ENV['VERBOSE'] ? it.logger(STDOUT) : it
  end
end

Cassandra::Mapper.schema = { keyspaces: [:flow] }
Cassandra::Mapper.env    = :test
# TODO: rename to :force_migrate_when_conflict!
Cassandra::Mapper.force_migrate

RSpec.configure do |config|
  config.include PropagateHelpers

  config.before do
    stub_const 'Flow::Queue::ACTIONS', {}
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
