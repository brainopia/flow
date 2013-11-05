require 'flow'

module Flow::Queue
  PROVIDERS = {}
  ACTIONS = {}

  require_relative 'queue/provider'
  require_relative 'queue/route'

  def push(queue, message)
    push_raw queue, Marshal.dump(message)
  end

  def pull(queue)
    Marshal.load pull_raw queue
  end
end
