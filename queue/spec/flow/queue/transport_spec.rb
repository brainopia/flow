require 'spec_helper'

describe Flow::Queue::Transport do
  let(:queue_name) { :somewhere } 
  let(:data) {{ wo: :ow }}
  let(:storage_1) { [] }
  let(:storage_2) { [] }
  let(:flow_1) { flow :foo, storage_1 }
  let(:flow_2) { flow :bar, storage_2 }

  def flow(label, storage)
    Flow
      .label(label)
      .queue_transport(queue_name)
      .store(storage)
  end

  before do
    [flow_1, flow_2].each do |flow|
      queue_for(flow).drop
    end
  end

  it 'should intercept data' do
    flow_1.trigger :insert, data
    storage_1.should be_empty
  end

  it 'should deliver data' do
    scheduler = scheduler_for flow_1
    flow_1.trigger :insert, data
    scheduler.run
    storage_1.should == [ data ]
  end

  it 'should deliver to appropriate action' do
    scheduler = scheduler_for flow_1, flow_2

    flow_2.trigger :insert, n: 1
    flow_1.trigger :insert, n: 2
    flow_2.trigger :insert, n: 3

    scheduler.run

    storage_1.should == [{ n: 2 }]
    storage_2.should == [{ n: 1 }, { n: 3 }]
  end
end
