require 'spec_helper'

describe Flow::Cassandra::Target do
  let(:mapper) do
    Cassandra::Mapper.new :flow, :test_target do
      key :age
      subkey :name
      type :age, :integer
    end
  end

  let(:flow) { Flow.cassandra_target mapper }
  let(:person_1) {{ name: 'Peter', age: 30 }}
  let(:person_2) {{ name: 'Charles', age: 36 }}

  it 'should insert records' do
    insert person_1, person_2
    mapper.all.should == [ person_1, person_2 ]
  end

  it 'should remove records' do
    insert person_1, person_2
    remove person_1
    mapper.all.should == [ person_2 ]
  end
end
