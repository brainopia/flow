require 'spec_helper'

describe Flow::Action::Union do
  let(:storage) { [] }
  let(:flow_1) { Flow.derive {|it| it.merge branch: 1 }}
  let(:flow_2) { Flow.derive {|it| it.merge branch: 2 }}
  let(:flow_3) { Flow.derive {|it| it.merge branch: 3 }}
  let(:data) {{ foo: :bar }}

  def branch(number)
    data.merge branch: number
  end

  context 'on base of existing flow' do
    before do
      flow_1.union(flow_2, flow_3).store storage
    end

    it 'propagate in base flow' do
      flow_1.trigger :insert, data
      storage.should == [ branch(1) ]
    end

    it 'propagate in side flow' do
      flow_2.trigger :insert, data
      flow_3.trigger :insert, data
      storage.should == [ branch(2), branch(3) ]
    end
  end

  context 'on new flow' do
    before do
      Flow.union(flow_1, flow_2, flow_3).store storage 
    end

    it 'propagate' do
      flow_2.trigger :insert, data
      storage.should == [ branch(2) ]
    end
  end
end
