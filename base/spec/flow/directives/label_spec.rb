require 'spec_helper'

describe Flow::Directive::Label do
  it 'should have an empty label by default' do
    Flow.label.should be nil
  end

  it 'should be set first time' do
    Flow.label('x').label.should == 'x'
  end

  it 'should be appended subsequent times' do
    Flow.label('x').label('y').label.should == 'x_y'
  end
end
