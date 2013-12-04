class Flow::Action::IfMatch < Flow::Action
  attr_reader :block_children

  def setup!(field, value=Flow::DEFAULT_ARGUMENT, &block)
    @field = field
    @value = value

    if block
      block.call new_flow

      unless @children.empty?
        @block_children  = @children
        @children        = []
      end
    end
  end

  def new_flow
    return super unless @block_children

    subflows = endpoints(@block_children).map(&:new_flow)
    super.union(*subflows).copy_location(self)
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
