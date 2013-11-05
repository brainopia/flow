require 'spec_helper'

describe Flow::Queue::Route do
  let(:count) { double }
  let(:redis) { double.as_null_object }
  let(:flow) { Flow.queue_route :somewhere }

  before do
    stub_const 'Flow::Queue::ACTIONS', {}
    stub_const 'Flow::Queue::PROVIDERS', redis: redis
  end

  it 'should intercept data' do
    count.should_not_receive(:after_route)
    flow.check { count.after_route }
    flow.trigger_root :insert, data: true
  end

  it 'should deliver data to queue' do
    message = { action: 'queue_route', data: { foo: :bar }}
    redis.should_receive(:push).with :somewhere, message
    flow.trigger_root :insert, message[:data]
  end

  it 'should register action for queue' do
    flow = Flow.label(:foo).queue_route :bar
    Flow::Queue::ACTIONS.should == { 'queue_route_foo' => flow.action }
  end
end
