require 'spec_helper'

describe Flow::Queue::Provider do
  context 'no provider' do
    it 'should raise' do
      expect { Flow.queue_provider }.to raise_exception
    end
  end

  context 'one provider' do
    before do
      stub_const "Flow::Queue::PROVIDERS", { redis: 'foo' }
    end

    it 'should return default provider' do
      Flow.queue_provider.should == 'foo'
    end

    it 'should set provider' do
      Flow.queue_provider(:redis).queue_provider.should == 'foo'
    end

    it 'should raise for incorrect provider' do
      expect { Flow.queue_provider(:missing) }.to raise_exception
    end
  end

  context 'many providers' do
    before do
      stub_const "Flow::Queue::PROVIDERS", { redis: 'foo', kafka: 'bar' }
    end

    it 'should raise without selected provider' do
      expect { Flow.queue_provider }.to raise_exception
    end

    it 'should return selected provider' do
      Flow.queue_provider(:kafka).queue_provider.should == 'bar'
    end

    it 'should raise for incorrect provider' do
      expect { Flow.queue_provider(:missing) }.to raise_exception
    end
  end
end
