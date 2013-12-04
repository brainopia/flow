class Flow::Action
  UnknownType = Class.new ArgumentError

  class << self
    def inherited(klass)
      Flow.action klass
    end

    def action_name
      Flow::Utilities::Format.pretty_name self
    end

    def shortcut(name)
      previous_name = action_name
      rename = proc { alias_method name, previous_name }
      Flow.class_eval &rename
      Flow.instance_eval &rename
    end
  end

  attr_reader :location, :parents, :children, :name, :flow

  def initialize(flow, action=nil)
    @flow     = flow
    @location = determine_location
    @parents  = []
    @children = []
    @name     = self.class.action_name

    add_parent action if action
  end

  def add_parent(action)
    parents << action
    action.add_child self
  end

  def add_child(action)
    children << action
  end

  def propagate(type, data)
    data = transform type, data
    propagate_next type, data
  end

  def transform(type, data)
    data
  end

  def propagate_next(type, data)
    propagate_for children, type, data
  end

  def propagate_for(actions, type, data)
    log do |it|
      it.puts name
      it.puts "location - #{location}"
      it.puts "destinations - #{actions.map(&:location)}"
      it.puts type
      it.puts data.inspect
    end

    propagation = ->(it) do
      actions.map do |action|
        begin
          action.propagate type, it.dup
        rescue Flow::Error
          $!.prepend_location action.location
          raise
        rescue
          raise Flow::Error.new(action.location, $!)
        end
      end
    end

    if data.is_a? Array
      data.each(&propagation)
    elsif data
      propagation.call data
    end
  end

  def endpoints(actions=children)
    return [self] if actions.empty?
    actions.flat_map(&:endpoints)
  end

  def root
    return self if parents.empty?
    parents.first.root
  end

  def inspect
    "#{self.class.name}: #{location} #{name}"
  end

  def extend_name(string)
    name << '_' << string.to_s
  end

  private

  def log(&block)
    if flow.logger
      block.call flow.logger
      flow.logger.puts "\n"*2
    end
  end

  def log_inspect(entry)
    log {|it| it.puts "inspect: #{entry.inspect}" }
  end

  def determine_location
    callsite = caller[3].include?('forwardable') ? caller[4] : caller[3]
    callsite.gsub(/(:in.*)|(#{Dir.pwd}\/)/, '')
  end
end
