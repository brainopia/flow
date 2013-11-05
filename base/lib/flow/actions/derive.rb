class Flow::Action::Derive < Flow::Action
  def setup!(&callback)
    @callback = callback
  end

  def transform(type, data)
    @callback.call data
  end
end
