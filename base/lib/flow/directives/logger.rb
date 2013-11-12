class Flow::Directive::Logger < Flow::Directive
  def get
    @logger
  end

  def set(logger)
    raise ArgumentError unless logger.respond_to? :puts
    @logger = logger
  end
end
