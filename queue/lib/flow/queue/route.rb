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
    existing_action = Flow::Queue::ACTIONS_BY_QUEUE[queue_name.to_sym]
    if existing_action
      raise <<-ERROR
        duplicate queue action with queue #{queue_name}"
        existing action location: #{existing_action.location}
        current action location:  #{location}
      ERROR
    else
      Flow::Queue::ACTIONS_BY_QUEUE[queue_name.to_sym] = self
    end
  end
end
