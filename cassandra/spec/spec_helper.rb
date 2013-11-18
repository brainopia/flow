require 'flow/cassandra'
require 'flow/queue/redis'

if ENV['VERBOSE']
  def Flow.default
    new.logger STDOUT
  end
end

Cassandra::Mapper.schema = { keyspaces: [:flow] }
Cassandra::Mapper.env    = :test
# TODO: rename to :force_migrate_when_conflict!
Cassandra::Mapper.force_migrate

RSpec.configure do |config|
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
