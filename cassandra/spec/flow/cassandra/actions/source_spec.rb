require 'spec_helper'

describe Flow::Cassandra::Source do
  let(:mapper) do
    Cassandra::Mapper.new :flow, :test_target do
      key :age
      subkey :name
      type :age, :integer
    end
  end

  let(:storage) { [] }
  let(:person) {{ age: 10, name: 'Steve' }}

  it 'should connect target to source' do
    Flow
      .cassandra_source(mapper)
      .store storage

    Flow
      .cassandra_target(mapper)
      .trigger :insert, person

    storage.should == [ person ]
  end

  it 'should connect source to target' do
    target = Flow.cassandra_target mapper

    Flow
      .cassandra_source(mapper)
      .store storage

    target.trigger :insert, person
    storage.should == [ person ]
  end
end
