class Flow::Error < StandardError
  attr_reader :cause, :locations
  # Support honeybadger until they merge my PR
  alias original_exception cause

  def initialize(location, error=$!)
    @cause     = error
    @locations = [location]
  end

  def backtrace
    formatted_locations + cause.backtrace
  end

  def message
    cause.message
  end

  def formatted_locations
    locations.map {|it| "(flow: #{it})" }
  end
end
