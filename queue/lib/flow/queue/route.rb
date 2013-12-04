class Flow::Queue::Route < Flow::Action
  attr_reader :queue, :queue_name

  def setup!(queue_name=nil)
    if queue_name
      @queue_name = queue_name.to_sym
      @queue = flow.queue_provider.new queue_name
      Flow::Queue.register :queue, self, queue_name
    else
      raise ArgumentError
    end
  end

  def transform(type, data)
    queue.publish type, data
    nil
  end
end
