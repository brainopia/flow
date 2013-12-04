require 'forwardable'

class Flow
  DEFAULT_ARGUMENT = :default_argument

  class << self
    include SingleForwardable

    def default
      new
    end

    # hook to extend flow with additional actions
    def action(klass)
      def_delegator :default, klass.action_name
      define_method klass.action_name do |*args, &block|
        new_action = klass.new self, action
        directives.values.each {|it| it.setup! new_action }

        if new_action.respond_to? :setup!
          new_action.setup! *args, &block
          clone_with new_action
        elsif new_action.respond_to? :setup_with_flow!
          new_action.setup_with_flow! *args, &block
        else
          # to support inheritance of extended modules
          clone_with new_action
        end
      end
    end

    # hook to propagate settings across flow
    def directive(klass)
      name = klass.directive_name
      def_delegator :default, klass.directive_name

      define_method name do |value=DEFAULT_ARGUMENT|
        if value == DEFAULT_ARGUMENT
          directive_for(name, klass).get
        else
          clone.tap do |it|
            it.directives[name] = it.directive_for(name, klass).reset value
          end
        end
      end
    end
  end

  require_relative 'flow/utilities/format'
  require_relative 'flow/error'
  require_relative 'flow/directive'
  require_relative 'flow/directives/label'
  require_relative 'flow/directives/logger'
  require_relative 'flow/action'
  require_relative 'flow/actions/check'
  require_relative 'flow/actions/store'
  require_relative 'flow/actions/derive'
  require_relative 'flow/actions/union'
  require_relative 'flow/actions/if_match'
  require_relative 'flow/actions/unless_match'

  attr_accessor :action, :directives

  def initialize
    @directives = {}
  end

  def initialize_clone(_)
    @directives = directives.clone
  end

  def apply
    block_given? ? yield(self) : self
  end

  def trigger(type, data)
    action.root.propagate type, data
  end

  def clone_with(action)
    clone.tap {|it| it.action = action }
  end

  def directive_for(name, klass)
    directives[name] ||= klass.new
  end
end
