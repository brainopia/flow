require 'spec_helper'

describe Flow::Queue::Route do
  let(:count) { double }
  let(:redis) { double.as_null_object }
  let(:queue_name) { :somewhere } 
  let(:actions_by_queue) { Flow::Queue::ACTIONS_BY_QUEUE }
  let(:flow) { Flow.queue_route queue_name }

  before do
    stub_const 'Flow::Queue::PROVIDERS', redis: redis
  end

  it 'should intercept data' do
    count.should_not_receive(:after_route)
    flow.check { count.after_route }
    flow.trigger :insert, data: true
  end

  it 'should register action for queue' do
    flow = Flow.queue_route queue_name
    actions_by_queue.should == { queue_name => flow.action }
  end

  it 'should deliver data' do
    queue_stub = double

    redis.should_receive(:new).with(queue_name).and_return queue_stub
    queue_stub.should_receive(:publish).with :insert, foo: :bar

    flow.trigger :insert, foo: :bar
  end
end
