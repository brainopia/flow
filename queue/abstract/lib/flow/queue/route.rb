class Flow::Queue::Route < Flow::Action
  def setup!(queue)
    @queue = queue
    register_queue_action!
  end

  def transform(type, data)
    flow.queue_provider.publish @queue, wrap(data)
    nil
  end

  private

  def wrap(data)
    Flow::Queue::Message.wrap name, data
  end

  def register_queue_action!
    if Flow::Queue::ACTIONS[name]
      raise "duplicate queue action with name #{name}"
    else
      Flow::Queue::ACTIONS[name] = self
    end
  end
end
