class Cassandra::Mapper
  attr_reader :publishers, :subscribers

  def action(type, action)
    @publishers ||= []
    @subscribers ||= []

    case type
    when :publisher
      @publishers << action
      @subscribers.each do |it|
        it.add_parent action
      end
    when :subscriber
      @subscribers << action
      @publishers.each do |it|
        action.add_parent it
      end
    else
      raise ArgumentError, type
    end
  end
end
