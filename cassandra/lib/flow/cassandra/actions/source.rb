class Flow::Cassandra::Source < Flow::Action
  def setup!(mapper)
    mapper.action :subscriber, self
  end
end
