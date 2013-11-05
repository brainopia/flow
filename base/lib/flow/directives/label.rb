class Flow::Directive::Label < Flow::Directive
  def get
    @label
  end

  def set(suffix)
    if @label
      @label += '_' + suffix.to_s
    else
      @label = suffix.to_s
    end
  end

  def setup!(action)
    action.improve_name @label if @label
  end
end
