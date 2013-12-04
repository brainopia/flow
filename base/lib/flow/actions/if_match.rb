class Flow::Action::IfMatch < Flow::Action
  def setup_with_flow!(field, value=Flow::DEFAULT_ARGUMENT, &block)
    @field = field
    @value = value
    new_flow = flow.clone_with(self)

    if block
      block.call new_flow

      if @children.empty?
        new_flow
      else
        @block_children  = @children
        @children        = []
        subflows = endpoints(@block_children).map(&:flow)
        new_flow.union(*subflows).copy_location(self)
      end
    else
      new_flow
    end
  end

  def propagate(type, data)
    matched = matches? data
    if @block_children and matched
      propagate_for @block_children, type, data
    elsif @block_children or matched
      propagate_next type, data
    end
  end

  private

  def matches?(data)
    actual_value = data[@field]

    case @value
    when Array
      @value.include? actual_value
    when Flow::DEFAULT_ARGUMENT
      actual_value
    else
      @value == actual_value
    end
  end
end
