class Flow::Cassandra::Source < Flow::Action
  attr_reader :mapper

  def setup!(mapper)
    @mapper = mapper
    mapper.action :subscriber, self
  end
end
