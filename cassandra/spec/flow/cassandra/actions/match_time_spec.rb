require 'spec_helper'

describe Flow::Cassandra::MatchTime do
  let(:storage) { [] }

  let(:mapper) do
    Cassandra::Mapper.new :flow, :sessions do
      key    :user
      subkey :created_at
      type   :created_at, :time
    end
  end

  let(:mapper_flow) do
    Flow.cassandra_target mapper
  end

  let(:flow) do
    Flow
      .cassandra_match_time(mapper) {|order, session|
        order[:source] = session[:source] if session
        order
      }
      .store storage
  end

  let(:time) { Time.at Time.now.to_i }
  let(:order) {{ order: 1, user: 'mark', created_at: time }} 

  it 'should insert one record' do
    insert flow, order
    storage.should == [ order ]
  end

  it 'should remove one record' do
    remove flow, order
    storage.should == []
  end
end
