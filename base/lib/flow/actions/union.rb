class Flow::Action::Union < Flow::Action
  def setup!(*flows)
    flows.each do |flow|
      add_parent flow.action
    end
  end
end
