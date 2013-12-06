class Flow::Queue::Transport < Flow::Action
  attr_reader :queue, :router

  def setup!(queue=nil, &router)
    Flow::Queue.register :name, self, name

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
    if queue
      queue = flow.queue_provider.new queue
      queue.push wrap(type, data)
      nil
    else
      data
    end
  end

  private

  def wrap(type, data)
    { action: name, type: type, data: data }
  end
end
