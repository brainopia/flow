class Flow::Cassandra::Target < Flow::Action
  attr_reader :mapper

  def setup!(mapper)
    if mapper.is_a? Cassandra::Mapper
      mapper.action :publisher, self
      @mapper = mapper
    else
      raise ArgumentError, "bad target: #{mapper}"
    end
  end

  def transform(type, data)
    case type
    when :insert, :remove
      mapper.send type, data
    when :check
      key = self.key data
      objects = mapper.get key
      log_inspect key
      log_inspect objects
      data
    else
      raise UnknownType, type
    end
  end

  private

  def key(data)
    target.config.key.each_with_object({}) do |field, result|
      result[field] = data[field]
    end
  end
end
