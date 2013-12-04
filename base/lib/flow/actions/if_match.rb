class Flow::Action::IfMatch < Flow::Action
  def setup!(field, value=Flow::DEFAULT_ARGUMENT, &block)
    @field = field
    @value = value
    if block
      block.call flow.clone_with(self)
      unless @children.empty?
        @block_children  = @children
        @block_endpoints = endpoints @block_children
        @children        = []
      end
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

  def add_child(action)
    super
    return unless @block_endpoints
    @block_endpoints.each do |it|
      action.add_parent it
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
