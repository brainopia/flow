module Helpers
  def propagate(type, flow, records)
    records.each do |record|
      flow.trigger type, record
    end
  end

  def insert(flow, *records)
    propagate :insert, flow, records
  end

  def remove(flow, *records)
    propagate :remove, flow, records
  end

  def scheduler
    $scheduler ||= begin
      queues = Flow::Cassandra.ring('flow_test').local_queues
      Floq::Schedulers::Test.new queues: queues
    end
  end
end
