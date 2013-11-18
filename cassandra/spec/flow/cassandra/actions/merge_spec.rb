require 'spec_helper'

describe Flow::Cassandra::Merge do
  let(:storage) { [] }
  let(:flow) do
    Flow
      .cassandra_merge(:user_id) {|current, previous|
        new_result = (previous || {}).merge current
        if previous
          new_result[:updates] += 1
        else
          new_result[:updates] = 0
        end
        new_result
      }.store storage
  end

  context 'one record' do
    let(:create_user) {{ user_id: 1, gender: :male, age: 20 }}

    it 'insert' do
      insert create_user
      storage.should == [ create_user.merge(updates: 0) ]
    end

    it 'remove' do
      insert create_user
      remove create_user
      storage.should be_empty
    end
  end

  context 'several records' do
    let(:create_user) {{ user_id: 1, gender: :male, age: 20 }}
    let(:update_user) {{ user_id: 1, gender: :female }}

    it 'insert' do
      insert create_user, update_user
      storage.should == [{ user_id: 1, gender: :female, age: 20, updates: 1 }]
    end

    it 'remove first' do
      insert create_user, update_user
      remove create_user
      storage.should == [ update_user.merge(updates: 0) ]
    end

    it 'remove last' do
      insert create_user, update_user
      remove update_user
      storage.should == [ create_user.merge(updates: 0) ]
    end
  end
end
