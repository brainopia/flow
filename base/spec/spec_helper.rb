require 'flow'

if ENV['VERBOSE']
  def Flow.default
    new.logger STDOUT
  end
end
