class Flow::Cassandra::Keyspace < Flow::Directive
  def initialize
    @name ||= :views
  end

  def get
    @name
  end

  def set(keyspace)
    @name = keyspace
  end
end
