require 'spec_helper'

describe Flow::Queue::Route do
  let(:queue_name) { :somewhere } 
  let(:storage) { [] }
  let(:data) {{ foo: :bar }}
  let(:flow) do
    Flow
      .queue_route(queue_name)
      .store(storage)
  end

  before do
    queue_for(flow).drop
  end

  it 'should intercept data' do
    flow.trigger :insert, data
    storage.should be_empty
  end

  it 'should deliver data' do
    scheduler = scheduler_for flow
    flow.trigger :insert, data
    scheduler.run
    storage.should == [ data ]
  end
end
