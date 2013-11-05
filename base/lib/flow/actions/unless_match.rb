class Flow::Action::UnlessMatch <  Flow::Action::IfMatch
  def matches?(*)
    not super
  end
end
