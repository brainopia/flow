require 'spec_helper'

describe Flow::Action::Check do
  let(:data) {{ x: 1, y: 2 }}
  let(:count) { double }

  it 'should check content of the flow' do
    count.should_receive(:in_flow).once

    flow = Flow.check do |it|
      it.should == data
      count.in_flow
    end

    flow.trigger :insert, data
  end

  it 'should ignore an unfit type' do
    count.should_not_receive(:in_flow)

    flow = Flow.check(:remove) { count.in_flow }
    flow.trigger :insert, data
  end

  it 'should accept a matching type' do
    count.should_receive(:in_flow).once

    flow = Flow.check(:insert) { count.in_flow }
    flow.trigger :insert, data
  end
end
