require 'flow/queue'
require 'cassandra/mapper'

# TODO: support replay by keeping hash of initial data as id
# and ignoring events who's already in cache
module Flow::Cassandra
  require_relative 'cassandra/directives/keyspace'
  require_relative 'cassandra/actions/flag'

  def scope_value_for(data)
    [name, scope.map {|it| data[it] }].join('.')
  end
end
