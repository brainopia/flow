class Flow::Action::Store < Flow::Action
  attr_reader :storage

  def setup!(array=[])
    @storage = array
  end

  def transform(type, data)
    case type
    when :insert
      storage << data
    when :remove
      index = storage.index data
      storage.delete_at index if index
    end
    data
  end
end
