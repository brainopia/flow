require 'flow/queue'

RSpec.configure do |config|
  config.before do
    stub_const 'Flow::Queue::PROVIDERS', provider: double.as_null_object
    stub_const 'Flow::Queue::ACTIONS_BY_NAME', {}
    stub_const 'Flow::Queue::ACTIONS_BY_QUEUE', {}
  end
end
