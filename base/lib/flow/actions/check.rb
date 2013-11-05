class Flow::Action::Check < Flow::Action
  def setup!(type=nil, &callback)
    @type     = type
    @callback = callback
  end

  def transform(type, data)
    if not @type or @type == type
      @callback.call data
    end
    data
  end
end
