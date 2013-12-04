class Flow::Queue::Receive < Flow::Action
  def setup!(queue_name)
    parents.each {|it| it.children.delete self }
    @queue_name = queue_name
  end

  def new_flow
    flow.union(router).copy_location(self)
  end

  private

  def router
    empty_flow.queue_route(@queue_name).copy_location(self)
  end
end
