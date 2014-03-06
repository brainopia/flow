class Flow::Error < StandardError
  attr_reader :cause
  # Support honeybadger until they merge my PR
  alias original_exception cause

  def initialize(location, error=$!)
    @cause     = error
    @locations = [format(location)]
  end

  def backtrace
    @locations + cause.backtrace
  end

  def message
    cause.message
  end

  def prepend_location(location)
    @locations.push format location
  end

  private

  def format(location)
    "(flow: #{location})"
  end
end
