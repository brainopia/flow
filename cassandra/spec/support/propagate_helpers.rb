module PropagateHelpers
  def propagate(type, records)
    records.each do |record|
      flow.trigger type, record
      Flow::Cassandra::ROUTERS.values.each do |router|
        router.pull_and_propagate Flow::Queue::Redis
      end
    end
  end

  def insert(*records)
    propagate :insert, records
  end

  def remove(*records)
    propagate :remove, records
  end
end
