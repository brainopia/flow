class Flow::Queue::Route < Flow::Action
  attr_reader :queue

  def setup!(queue)
    @queue = flow.queue_provider.new queue
    register_queue_action!
  end

  def transform(type, data)
    @queue.push wrap(type, data)
    nil
  end

  private

  def wrap(type, data)
    { action: name, type: type, data: data }
  end

  def register_queue_action!
    if Flow::Queue::ACTIONS[name]
      raise "duplicate queue action with name #{name}"
    else
      Flow::Queue::ACTIONS[name] = self
    end
  end
end
