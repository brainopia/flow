require 'spec_helper'

describe Flow::Queue::Receive do
  let(:storage) { [] }
  let(:queue_name) { :somewhere }
  let(:data) {{ foo: :bar } }
  let(:flow) do
    Flow
      .derive {|it| it.merge primary: true }
      .queue_receive(queue_name)
      .store storage
  end

  before do
    stub_const 'Flow::Queue::ACTIONS', {}
    stub_const 'Flow::Queue::PROVIDERS', redis: double
  end

  it 'should work as usual' do
    flow.trigger :insert, data
    storage.should == [ data.merge(primary: true) ]
  end

  it 'should receive messages from queue' do
    flow
    Flow::Queue::ACTIONS.values.first.propagate_next :insert, data
    storage.should == [ data ]
  end
end
