require 'spec_helper'

describe Flow::Cassandra::Keyspace do
  it 'should be views by default' do
    Flow.cassandra_keyspace.should == :views
  end
end
