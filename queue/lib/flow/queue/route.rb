class Flow::Queue::Route < Flow::Action
  REGISTRY = {}
  attr_reader :queue

  def setup!(queue, type=:parallel)
    if queue.is_a?(String) or queue.is_a?(Symbol)
      @queue = Floq[queue, type]
    else
      @queue = queue
    end
    register
    wire_handler
  end

  def transform(type, data)
    unless queue.push [type, data]
      data
    end
  end

  private

  def wire_handler
    queue.handle &method(:handler)
  end

  def handler((type, data))
    propagate_next type, data
  end

  def registry_key
    queue.name
  end

  def register
    existing_action = REGISTRY[registry_key]
    if existing_action
      raise <<-ERROR
        duplicate #{self.class}: #{registry_key}
        conflicting flow locations: \n#{ existing_action.main_locations.join("\n") }
        current flow locations: \n#{ main_locations.join("\n") }
      ERROR
    else
      REGISTRY[registry_key] = self
    end
  end
end
