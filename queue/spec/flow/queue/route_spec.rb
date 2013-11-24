require 'spec_helper'

describe Flow::Queue::Route do
  let(:count) { double }
  let(:redis) { double.as_null_object }
  let(:queue_name) { :somewhere }

  before do
    stub_const 'Flow::Queue::ACTIONS', {}
    stub_const 'Flow::Queue::PROVIDERS', redis: redis
  end

  shared_examples_for :all_queues do
    it 'should intercept data' do
      count.should_not_receive(:after_route)
      flow.check { count.after_route }
      flow.trigger :insert, data: true
    end

    it 'should register action for queue' do
      flow = Flow.label(:foo).queue_route :bar
      Flow::Queue::ACTIONS.should == { 'queue_route_foo' => flow.action }
    end

    it 'should deliver data' do
      message = { action: 'queue_route', type: :insert, data: { foo: :bar }}
      queue_stub = double

      redis.should_receive(:new).with(queue_name).and_return queue_stub
      queue_stub.should_receive(:push).with message

      flow.trigger :insert, message[:data]
    end
  end

  context 'static queue' do
    let(:flow) { Flow.queue_route queue_name }
    it_behaves_like :all_queues
  end

  context 'dynamic queue' do
    let(:flow) { Flow.queue_route { queue_name }}
    it_behaves_like :all_queues
  end
end
