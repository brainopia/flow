require 'spec_helper'

describe Flow::Cassandra::Flag do
  let(:storage) { [] }
  let(:flow) do
    Flow
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

  context 'propagate insertion' do
    it 'one record' do
      insert flow, male(15)
      storage.should == [youngest(male(15))]
    end

    it 'several records in increasing order' do
      insert flow, male(15), male(17), male(19)
      storage.should == [
        youngest(male(15)),
        male(17),
        male(19)
      ]
    end

    it 'several records in mixed order' do
      insert flow, male(17), male(15), male(19)
      storage.should == [
        male(17),
        youngest(male(15)),
        male(19)
      ]
    end

    it 'records with different scope' do
      insert flow, male(20), female(19)
      storage.should == [
        youngest(male(20)),
        youngest(female(19))
      ]
    end
  end

  context 'propagate removal' do
    it 'one record' do
      insert flow, female(20)
      remove flow, female(20)
      storage.should be_empty
    end

    it 'several records with one scope' do
      insert flow, female(20), female(15), female(17)
      remove flow, female(15)
      storage.should == [
        female(20),
        youngest(female(17))
      ]
    end

    it 'several records with different scope' do
      insert flow, female(17), female(20), male(20), male(17)
      remove flow, female(20), male(17)
      storage.should == [
        youngest(female(17)),
        youngest(male(20))
      ]
    end
  end
end
