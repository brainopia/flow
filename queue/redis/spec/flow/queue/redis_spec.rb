require 'spec_helper'

describe Flow::Queue::Redis do
  let(:count) { double }
  let(:data) {{ foo: :bar }}
  let(:queue_name) { :somewhere }
  let(:queue) { Flow::Queue::Redis.new queue_name }

  before do
    queue.clear
    stub_const 'Flow::Queue::ACTIONS', {}
  end

  it 'should push messages' do
    Flow
      .queue_route(queue_name)
      .trigger :insert, foo: :bar

    queue.pull.should == {
      action: 'queue_route',
      type:   :insert,
      data:   { foo: :bar }
    }
  end

  it 'should propagate tasks futher' do
    count.should_receive(:after_route).once

    Flow
      .queue_route(queue_name)
      .check {|it| it.should == data; count.after_route }
      .trigger :insert, data

    queue.pull_and_propagate
  end
end
