require 'spec_helper'

describe Flow::Queue::Redis do
  let(:count) { double }
  let(:data) {{ foo: :bar }}
  before do
    Flow::Queue::Redis.clear :foo
    stub_const 'Flow::Queue::ACTIONS', {}
  end

  it 'should push messages' do
    Flow.queue_route(:somewhere).trigger :insert, foo: :bar
    Flow::Queue::Redis.pull(:somewhere).should == {
      action: 'queue_route',
      type:   :insert,
      data:   { foo: :bar }
    }
  end

  it 'should propagate tasks futher' do
    count.should_receive(:after_route).once

    Flow
      .queue_route(:somewhere)
      .check {|it| it.should == data; count.after_route }
      .trigger_root :insert, data

    Flow::Queue::Redis.handle_once :somewhere
  end
end
