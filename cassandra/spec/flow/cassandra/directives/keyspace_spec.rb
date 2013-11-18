require 'spec_helper'

describe Flow::Cassandra::Keyspace do
  it 'should be flow by default' do
    Flow.cassandra_keyspace.should == :flow
  end

  it 'should be configurable' do
    flow = Flow.cassandra_keyspace(:facts)
    flow.cassandra_keyspace.should == :facts
  end
end
