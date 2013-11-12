require 'spec_helper'

describe Flow::Directive::Logger do
  it 'should be nil by default' do
    Flow.logger.should_not be unless ENV['VERBOSE']
  end

  it 'should have an accessor' do
    Flow.logger(STDOUT).logger.should == STDOUT
  end

  it 'should raise if logger does not respond to puts' do
    expect { Flow.logger(:something) }.to raise_exception
  end
end
