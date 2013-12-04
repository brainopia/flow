class Flow::Queue::Receive < Flow::Action
  def setup_with_flow!(queue_name)
    parents.each {|it| it.children.delete self }
    router = flow.clone_with(nil).queue_route(queue_name)
    router.location = location
    flow.union(router).tap {|it| it.action.location = location }
  end
end
