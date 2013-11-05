class Flow::Directive
  class << self
    def inherited(klass)
      Flow.directive klass
    end

    def directive_name
      Flow::Utilities::Format.pretty_name self
    end
  end

  def setup!(action)
  end
end
