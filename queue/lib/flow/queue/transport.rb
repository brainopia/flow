class Flow::Queue::Transport < Flow::Queue::Route
  def transform(type, data)
    unless queue.push action: name, type: type, data: data
      data
    end
  end

  private

  def registry_key
    name
  end

  def handler(message)
    action = REGISTRY.fetch message[:action]
    action.propagate_next message[:type], message[:data]
  end
end
