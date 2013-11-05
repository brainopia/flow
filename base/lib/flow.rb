require 'forwardable'

class Flow
  DEFAULT_ARGUMENT = :default_argument
  DEFAULT_DIRECTIVES = {}

  class << self
    include SingleForwardable
    attr_accessor :logger # TODO: turn into directive

    # hook to extend flow with additional actions
    def action(klass)
      def_delegator :new, klass.action_name
      define_method klass.action_name do |*args, &block|
        new_action = klass.new self, action
        directives.values.each {|it| it.setup! new_action }
        new_action.setup! *args, &block
        # to support inheritance of extended modules
        clone_with new_action
      end
    end

    # hook to propagate settings across flow
    def directive(klass)
      name = klass.directive_name
      DEFAULT_DIRECTIVES[name] = klass.new
      def_delegator :new, klass.directive_name

      define_method name do |value=DEFAULT_ARGUMENT|
        if value == DEFAULT_ARGUMENT
          directives[name].get
        else
          new_flow = clone
          new_directives = new_flow.directives.dup
          new_directive = new_directives[name].dup
          new_directive.set value
          new_directives[name] = new_directive
          new_flow.directives = new_directives
          new_flow
        end
      end
    end
  end

  require_relative 'flow/utilities/format'
  require_relative 'flow/error'
  require_relative 'flow/directive'
  require_relative 'flow/directives/label'
  require_relative 'flow/action'
  require_relative 'flow/actions/derive'
  require_relative 'flow/actions/check'
  require_relative 'flow/actions/if_match'
  require_relative 'flow/actions/unless_match'

  attr_accessor :action, :directives

  def initialize
    @directives = DEFAULT_DIRECTIVES.dup
  end

  def apply
    yield self if block_given?
  end

  def trigger(type, data)
    action.propagate type, data
  end

  def trigger_root(type, data)
    action.root.propagate type, data
  end

  def clone_with(action)
    clone.tap {|it| it.action = action }
  end
end
