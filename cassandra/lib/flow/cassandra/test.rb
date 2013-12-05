module Flow::Cassandra
  def self.propagate_all(provider)
    while router = ROUTERS.values.find {|it| it.tasks? provider }
      router.pull_and_propagate provider
    end
  end

  class Router
    def tasks?(provider)
      not dirty_queues(provider).empty?
    end

    def pull_and_propagate(provider)
      dirty_queues(provider).each do |it|
        provider.new(it).pull_and_propagate
      end
    end

    def dirty_queues(provider)
      local_queues.select do |it|
        provider.new(it).tasks?
      end
    end
  end
end

class Flow::Queue::Redis
  ALL = {}
  def self.new(*args)
    ALL[args] ||= super
  end

  module Inline
    def initialize(*)
      @tasks = 0
      super
    end

    def pull(blocking: true)
      super.tap {|it| @tasks -= 1 if it }
    end

    def push(message)
      @tasks += 1
      super
    end

    def tasks?
      @tasks > 0
    end

    def clear
      super if tasks?
    end
  end

  prepend Inline
end
