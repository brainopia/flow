require 'flow/cassandra'
require 'support/helpers'

def Flow.default
  new.cassandra_keyspace(:flow).apply do |it|
    ENV['VERBOSE'] ? it.logger(STDOUT) : it
  end
end

Floq.provider = Floq::Providers::Memory

Cassandra::Mapper.schema = { keyspaces: [:flow] }
Cassandra::Mapper.env    = :test
Cassandra::Mapper.force_migrate

RSpec.configure do |config|
  config.include Helpers

  config.before do
    stub_const 'Flow::Queue::Route::REGISTRY', {}
    scheduler.drop
    Cassandra::Mapper.clear!
  end
end
