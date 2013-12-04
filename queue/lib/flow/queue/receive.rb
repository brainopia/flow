class Flow::Queue::Receive < Flow::Action
  def setup_with_flow!(queue_name)
    parents.each {|it| it.children.delete self }
    flow.union flow.clone_with(nil).queue_route(queue_name)
  end
end
