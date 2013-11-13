class Flow::Error < StandardError
  attr_reader :message

  def initialize(location, error)
    @locations = [format(location)]
    @backtrace = error.backtrace
    @message   = error.message
  end

  def backtrace
    @locations + @backtrace
  end

  def prepend_location(location)
    @locations.push format location
  end

  private

  def format(location)
    "(flow: #{location})"
  end
end
