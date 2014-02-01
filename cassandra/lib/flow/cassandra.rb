require 'flow/queue'
require 'cassandra/mapper'

# TODO: support replay by keeping hash of initial data as id
# and ignoring events who's already in cache.
# Also check order of transactional actions, we have to first send remove
# and only then update catalog because if we'll be stopped mid-action
# everything will be replayed and we need to replay based on the old catalog entry
module Flow::Cassandra
  require_relative 'cassandra/ring'
  require_relative 'cassandra/local'
  require_relative 'cassandra/extensions/mapper'
  require_relative 'cassandra/extensions/token_range'
  require_relative 'cassandra/directives/keyspace'
  require_relative 'cassandra/actions/target'
  require_relative 'cassandra/actions/source'
  require_relative 'cassandra/actions/flag'
  require_relative 'cassandra/actions/merge'
  require_relative 'cassandra/actions/match_first'
  require_relative 'cassandra/actions/match_time'

  RINGS = Hash.new do |all, keyspace|
    all[keyspace] = Ring.new keyspace
  end

  def self.ring(keyspace)
    RINGS[keyspace.to_sym]
  end

  def self.rings
    RINGS.values
  end

  def scope_value_for(data)
    [name, scope.map {|it| data[it] }].join('.')
  end

  def keyspace
    flow.cassandra_keyspace
  end

  def prepend_router
    parents.dup.each do |parent|
      parents.delete parent
      parent.children.delete self
      router.add_parent parent
    end
    add_parent router
  end

  def router
    @router ||= begin
      transport = Flow::Queue::Transport.new empty_flow
      transport.location = location
      transport.extend_name name

      # flow.directives.values.each do |directive|
      #   directive.setup! transport
      # end

      ring = Flow::Cassandra.ring catalog.keyspace_name
      router = Flow::Queue::Router.new *ring.local_queues do |_,_,data|
        key_data = key data
        if key_data.values.all?
          token = catalog.token_for key_data
          ring.determine_queue token
        end
      end

      transport.setup! router
      transport
    end
  end
end
