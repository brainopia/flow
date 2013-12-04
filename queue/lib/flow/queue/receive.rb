class Flow::Queue::Receive < Flow::Action
  def setup_with_flow!(queue_name)
    parents.each {|it| it.children.delete self }
    router = empty_flow.queue_route(queue_name).copy_location(self)
    flow.union(router).copy_location(self)
  end
end
