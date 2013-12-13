class Flow::Queue::Transport < Flow::Queue::Route
  def transform(type, data)
    queue.push action: name, type: type, data: data
    nil
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
