class Flow::Queue::Receive < Flow::Action
  def setup_with_flow!(queue_name)
    flow.union Flow.queue_route(queue_name)
  end
end
