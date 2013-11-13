require 'spec_helper'

describe Flow::Action::Derive do
  let(:count) { double }

  it 'should modify data flow' do
    count.should_receive(:in_flow).once

    Flow
      .derive {|data| data.merge modified: true }
      .check {|data|
        data.should include :modified
        count.in_flow
      }.trigger :insert, {}
  end
end
