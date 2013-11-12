require 'flow/cassandra'

Cassandra::Mapper.schema = { keyspaces: [:flow] }
Cassandra::Mapper.env    = :test
# TODO: rename to :force_migrate_when_conflict!
Cassandra::Mapper.force_migrate

RSpec.configure do |config|
  config.before do
    Cassandra::Mapper.clear!
    Cassandra::Mapper.instances.each do |it|
      it.config.dsl.reset_callbacks!
    end
  end
end
