require 'flow'

class Flow::Queue
  PROVIDERS = {}
  ACTIONS = {}

  require_relative 'queue/provider'
  require_relative 'queue/route'

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

  def pull_and_propagate
    message = pull
    action = ACTIONS.fetch message[:action]
    action.propagate_next message[:type], message[:data]
  end

  def present?
    count > 0
  end

  def push(message)
    push_raw Marshal.dump message
  end

  def pull
    Marshal.load pull_raw
  end
end
