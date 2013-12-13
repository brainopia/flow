require 'flow/queue'

Floq.provider = Floq::Providers::Memory

RSpec.configure do |config|
  config.before do
    stub_const 'Flow::Queue::Route::REGISTRY', {}
  end

  config.include Module.new {
    def queue_for(flow)
      flow.actions.grep(Flow::Queue::Route).first.queue
    end

    def scheduler_for(*flows)
      queues = flows.map {|flow| queue_for flow }
      Floq::Schedulers::Test.new queues
    end
  }
end
