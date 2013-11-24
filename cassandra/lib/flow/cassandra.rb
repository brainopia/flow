require 'flow/queue'
require 'cassandra/mapper'
require 'system/getifaddrs'

# TODO: support replay by keeping hash of initial data as id
# and ignoring events who's already in cache.
# Also check order of transactional actions, we have to first send remove
# and only then update catalog because if we'll be stopped mid-action
# everything will be replayed and we need to replay based on the old catalog entry
module Flow::Cassandra
  require_relative 'cassandra/router'
  require_relative 'cassandra/extensions/mapper'
  require_relative 'cassandra/extensions/token_range'
  require_relative 'cassandra/directives/keyspace'
  require_relative 'cassandra/actions/target'
  require_relative 'cassandra/actions/source'
  require_relative 'cassandra/actions/flag'
  require_relative 'cassandra/actions/merge'
  require_relative 'cassandra/actions/match_first'
  require_relative 'cassandra/actions/match_time'

  ROUTERS = Hash.new do |all, keyspace|
    all[keyspace] = Router.new keyspace
  end

  def scope_value_for(data)
    [name, scope.map {|it| data[it] }].join('.')
  end

  def keyspace
    flow.cassandra_keyspace
  end

  def prepend_router
    if parents.empty?
      router_as_parent Flow
    else
      parents.each do |parent|
        parents.delete parent
        parent.children.delete self
        router_as_parent parent.flow
      end
    end
  end

  def router_as_parent(flow)
    router_flow = flow.queue_route do |data|
      token = catalog.token_for key(data)
      ROUTERS[catalog.keyspace_name].determine_queue token
    end
    add_parent router_flow.action
  end
end
