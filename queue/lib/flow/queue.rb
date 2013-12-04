require 'flow'

class Flow::Queue
  PROVIDERS = {}
  ACTIONS_BY_NAME = {}
  ACTIONS_BY_QUEUE = {}

  require_relative 'queue/provider'
  require_relative 'queue/route'
  require_relative 'queue/transport'
  require_relative 'queue/receive'

  def self.handle(*queues)
    queues.each do |name|
      Thread.new { new(name).run }
    end
  end

  def self.register(type, action, key)
    registry = const_get "ACTIONS_BY_#{type.upcase}"
    existing_action = registry[key]
    if existing_action
      raise <<-ERROR
        duplicate queue action with #{type}: #{key}
        conflicting flow locations: \n#{ existing_action.main_locations.join("\n") }
        current flow locations: \n#{ action.main_locations.join("\n") }
      ERROR
    else
      registry[key] = action
    end
  end

  attr_reader :name

  def initialize(name)
    @name = name.to_sym
  end

  def run
    loop { pull_and_propagate }
  end

  def pull_and_propagate(blocking: true)
    message = pull(blocking: blocking) or return
    action  = if message[:action]
      ACTIONS_BY_NAME.fetch message[:action]
    else
      ACTIONS_BY_QUEUE.fetch name
    end
    action.propagate_next message[:type], message[:data]
  end

  def present?
    count > 0
  end

  def push(message)
    push_raw Marshal.dump message
  end

  def publish(type, data)
    push type: type, data: data
  end

  def pull(blocking: true)
    message = pull_raw blocking: blocking
    Marshal.load message if message
  end
end
