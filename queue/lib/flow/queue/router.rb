class Flow::Queue::Router
  attr_reader :queues, :handler, :selector

  def initialize(*queues, &selector)
    @queues = queues
    @selector = selector
  end

  def handle(&handler)
    queues.each {|it| it.handle &handler }
    @handler = handler
  end

  def add(new_queues)
    new_queues.each {|it| it.handle &handler } if handler
    queues.concat new_queues
  end

  def push(message)
    if queue = selector.call(message)
      queue.push message
    end
  end
end
