module PropagateHelpers
  def propagate(type, flow, records)
    records.each do |record|
      flow.trigger type, record
      Flow::Cassandra.propagate_all Flow::Queue::Redis
    end
  end

  def insert(flow, *records)
    propagate :insert, flow, records
  end

  def remove(flow, *records)
    propagate :remove, flow, records
  end
end
