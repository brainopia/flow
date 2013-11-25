require 'spec_helper'

describe Flow::Queue::Receive do
  let(:storage) { [] }
  let(:queue_name) { :somewhere }
  let(:data) {{ foo: :bar } }
  let(:actions_by_queue) { Flow::Queue::ACTIONS_BY_QUEUE }
  let(:flow) do
    Flow
      .derive {|it| it.merge primary: true }
      .queue_receive(queue_name)
      .store storage
  end

  it 'should work as usual' do
    flow.trigger :insert, data
    storage.should == [ data.merge(primary: true) ]
  end

  it 'should receive messages from queue' do
    flow
    actions_by_queue.values.first.propagate_next :insert, data
    storage.should == [ data ]
  end
end
