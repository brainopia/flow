require 'flow'

class Flow::Queue
  PROVIDERS = {}
  ACTIONS = {}

  require_relative 'queue/provider'
  require_relative 'queue/route'
  require_relative 'queue/receive'

  def self.handle(*queues)
    queues.each do |name|
      Thread.new { new(name).run }
    end
  end

  attr_reader :name

  def initialize(name)
    @name = name
  end

  def run
    loop { pull_and_propagate }
  end

  def pull_and_propagate(blocking: true)
    message = pull blocking: blocking
    if message
      action = ACTIONS.fetch message[:action]
      action.propagate_next message[:type], message[:data]
    end
  end

  def present?
    count > 0
  end

  def push(message)
    push_raw Marshal.dump message
  end

  def pull(blocking: true)
    message = pull_raw blocking: blocking
    Marshal.load message if message
  end
end
