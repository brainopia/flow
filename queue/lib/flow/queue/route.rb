class Flow::Queue::Route < Flow::Action
  attr_reader :queue, :queue_name

  def setup!(queue_name=nil)
    if queue_name
      @queue_name = queue_name
      @queue = flow.queue_provider.new queue_name
      register_queue_action!
    else
      raise ArgumentError
    end
  end

  def transform(type, data)
    queue.publish type, data
    nil
  end

  private

  def register_queue_action!
    if Flow::Queue::ACTIONS_BY_QUEUE[queue_name.to_sym]
      raise "duplicate queue action with queue #{queue_name}"
    else
      Flow::Queue::ACTIONS_BY_QUEUE[queue_name.to_sym] = self
    end
  end
end
