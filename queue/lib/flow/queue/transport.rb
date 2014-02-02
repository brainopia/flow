class Flow::Queue::Transport < Flow::Queue::Route
  def transform(type, data)
    unless queue.push [name, type, data]
      data
    end
  end

  private

  def registry_key
    name
  end

  def handler((name, type, data))
    action = REGISTRY.fetch name
    action.propagate_next type.to_sym, data
  end
end
