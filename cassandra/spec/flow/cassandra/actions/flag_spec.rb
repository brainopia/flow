require 'spec_helper'

describe Flow::Cassandra::Flag do
  let(:storage) { [] }
  let(:flow) do
    Flow
      .cassandra_keyspace(:flow)
      .cassandra_flag(:youngest, :gender) {|current, previous|
        current[:age] < previous[:age] }
      .store storage
  end

  def male(age)
    { gender: 'male', age: age }
  end

  def female(age)
    { gender: 'female', age: age }
  end

  def youngest(person)
    person.merge(youngest: true)
  end

  def propagate(type, records)
    records.each do |record|
      flow.trigger type, record
      Flow::Cassandra::ROUTERS.values.each do |router|
        router.pull_and_propagate Flow::Queue::Redis
      end
    end
  end

  def insert(*records)
    propagate :insert, records
  end

  def remove(*records)
    propagate :remove, records
  end

  context 'propagate insertion' do
    it 'one record' do
      insert male(15)
      storage.should == [youngest(male(15))]
    end

    it 'several records in increasing order' do
      insert male(15), male(17), male(19)
      storage.should == [
        youngest(male(15)),
        male(17),
        male(19)
      ]
    end

    it 'several records in mixed order' do
      insert male(17), male(15), male(19)
      storage.should == [
        male(17),
        youngest(male(15)),
        male(19)
      ]
    end

    it 'records with different scope' do
      insert male(20), female(19)
      storage.should == [
        youngest(male(20)),
        youngest(female(19))
      ]
    end
  end

  context 'propagate removal' do
    it 'one record' do
      insert female(20)
      remove female(20)
      storage.should be_empty
    end

    it 'several records with one scope' do
      insert female(20), female(15), female(17)
      remove female(15)
      storage.should == [
        female(20),
        youngest(female(17))
      ]
    end

    it 'several records with different scope' do
      insert female(17), female(20), male(20), male(17)
      remove female(20), male(17)
      storage.should == [
        youngest(female(17)),
        youngest(male(20))
      ]
    end
  end
end
