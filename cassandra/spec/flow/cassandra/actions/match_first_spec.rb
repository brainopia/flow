require 'spec_helper'

describe Flow::Cassandra::MatchFirst do
  let(:storage) { [] }

  let(:mapper) do
    Cassandra::Mapper.new :flow, :test_target do
      key :user
      subkey :visit_at
      type :visit_at, :time
      type :age, :integer
    end
  end

  let(:mapper_flow) do
    Flow.cassandra_target mapper
  end

  let(:flow) do
    Flow
      .cassandra_match_first(mapper) {|user, visit|
        (visit || {}).merge user }
      .store storage
  end

  let(:time) { Time.at Time.now.to_i }

  def visit(user, time)
    { user: user, visit_at: time }
  end

  def user(user, age)
    { user: user, age: age }
  end

  context 'no match' do
    let(:polo) { user('polo', 30) }

    it 'insert one' do
      insert flow, polo
      scheduler.run
      storage.should == [ polo ]
    end

    it 'insert two' do
      insert flow, polo, polo
      scheduler.run
      storage.should == [ polo, polo ]
    end

    it 'remove one' do
      insert flow, polo, polo
      remove flow, polo
      scheduler.run
      storage.should == [ polo ]
    end

    it 'remove two' do
      insert flow, polo, polo
      remove flow, polo, polo
      scheduler.run
      storage.should == [ ]
    end
  end

  context 'initial match' do
    let(:marko) { user('marko', 22) }

    it 'one visit' do
      insert mapper_flow, visit('marko', time)
      insert flow, marko
      scheduler.run
      storage.should == [ marko.merge(visit_at: time) ]

      remove flow, marko
      scheduler.run
      storage.should == [ ]
    end
  end

  context 'late match' do
    let(:batman) { user('batman', 35) }

    it 'two visits' do
      insert flow, batman
      scheduler.run
      storage.should == [ batman ]

      insert mapper_flow, visit('batman', time + 10)
      scheduler.run
      storage.should == [ batman.merge(visit_at: time + 10) ]

      insert mapper_flow, visit('batman', time + 15)
      scheduler.run
      storage.should == [ batman.merge(visit_at: time + 10) ]

      remove mapper_flow, visit('batman', time + 10)
      scheduler.run
      storage.should == [ batman.merge(visit_at: time + 15) ]

      remove mapper_flow, visit('batman', time + 15)
      scheduler.run
      storage.should == [ batman ]
    end
  end
end
