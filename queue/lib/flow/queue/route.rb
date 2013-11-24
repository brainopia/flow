class Flow::Queue::Route < Flow::Action
  attr_reader :queue, :router

  def setup!(queue=nil, &router)
    register_queue_action!

    if router
      @router = router
    elsif queue
      @queue = queue
    else
      raise ArgumentError
    end
  end

  def transform(type, data)
    queue = @router ? @router.call(data) : @queue
    queue = flow.queue_provider.new queue
    queue.push wrap(type, data)
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
