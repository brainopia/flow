module Flow::Queue::Message
  extend self

  def wrap(action_name, data)
    { action: action_name, data: data }
  end

  def unwrap(message)
  end
end
