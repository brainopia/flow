require 'spec_helper'

describe Flow::Action::Store do
  let(:storage) { [] }
  let(:flow) { Flow.store storage }
  let(:data) {{ foo: :bar }}

  it 'should insert data' do
    flow.trigger :insert, data
    storage.should == [data]
  end

  it 'should remove data' do
    flow.trigger :insert, data
    flow.trigger :remove, data
    storage.should be_empty
  end

  it 'should remove only one record equal to data' do
    flow.trigger :insert, data
    flow.trigger :insert, data
    flow.trigger :remove, data
    storage.should == [data]
  end

  it 'should skip removal of missing data' do
    flow.trigger :insert, data
    flow.trigger :remove, data.merge(something: :different)
    storage.should == [data]
  end
end
