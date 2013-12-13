class Flow::Queue::Router
  attr_reader :queues, :handler, :selector

  def initialize(&selector)
    @queues = []
    @selector = selector
  end
  
  def handle(&handler)
    @handler = handler
  end

  def append(*new_queues)
    new_queues.each {|it| it.handle &handler } if handler
    queues.concat new_queues
  end

  def push(message)
    if queue_name = selector.call(message)
      if queue = queues.find {|it| it.name == queue_name }
        queue.push message
      else
        raise ArgumentError, queue_name
      end
    end
  end
end
