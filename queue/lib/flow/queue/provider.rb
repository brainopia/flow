class Flow::Queue::Provider < Flow::Directive
  def get
    @provider || default
  end

  def set(type)
    @provider = providers.fetch type
  end

  private

  def default
    if providers.size == 1
      providers.values.first
    elsif providers.size > 1
      raise 'unknown default queue provider'
    else
      raise 'missing queue provider'
    end
  end

  def providers
    Flow::Queue::PROVIDERS
  end
end
