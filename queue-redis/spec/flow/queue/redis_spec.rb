require 'spec_helper'

describe Flow::Queue::Redis do
  let(:count) { double }
  let(:data) {{ foo: :bar }}
  let(:queue_name) { :somewhere }
  let(:queue) { Flow::Queue::Redis.new queue_name }

  before do
    queue.clear
    stub_const 'Flow::Queue::ACTIONS_BY_NAME', {}
  end

  it 'should push messages' do
    Flow
      .queue_transport(queue_name)
      .trigger :insert, foo: :bar

    queue.pull.should == {
      action: 'queue_transport',
      type:   :insert,
      data:   { foo: :bar }
    }
  end

  it 'should propagate tasks futher' do
    count.should_receive(:after_queue).once

    Flow
      .queue_transport(queue_name)
      .check {|it| it.should == data; count.after_queue }
      .trigger :insert, data

    queue.pull_and_propagate
  end
end
