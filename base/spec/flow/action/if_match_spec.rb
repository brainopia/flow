require 'spec_helper'

describe Flow::Action::IfMatch do
  let(:count) { double }

  context 'without block' do
    it 'should filter records with missing field' do
      count.should_receive(:in_flow).once

      flow = Flow
        .if_match(:foo)
        .check do |data|
          count.in_flow
          data.should include(:foo)
        end

      flow.trigger_root :insert, bar: true
      flow.trigger_root :insert, foo: true
    end

    it 'should filter records with specified value' do
      count.should_receive(:in_flow).once

      flow = Flow
        .if_match(:foo, false)
        .check do |data|
          count.in_flow
          data.should include foo: false
        end

      flow.trigger_root :insert, foo: true
      flow.trigger_root :insert, foo: false
    end

    it 'should filter records with specified values' do
      count.should_receive(:in_flow).twice

      flow = Flow
        .if_match(:foo, [false, 'bar'])
        .check { count.in_flow }

      flow.trigger_root :insert, foo: false
      flow.trigger_root :insert, foo: true
      flow.trigger_root :insert, foo: 'bar'
    end
  end

  context 'with block' do
    it 'should filter records with missing field' do
      count.should_receive(:in_subflow).once
      count.should_receive(:in_flow).twice

      flow = Flow
        .if_match(:foo) {|subflow|
          subflow.check do |data|
            data.should include :foo
            count.in_subflow
          end
        }.check { count.in_flow }

      flow.trigger_root :insert, bar: true
      flow.trigger_root :insert, foo: true
    end

    it 'should filter records with specified value' do
      count.should_receive(:in_subflow).once
      count.should_receive(:in_flow).twice

      flow = Flow
        .if_match(:foo, 'bar') {|subflow|
          subflow.check do |data|
            data.should include foo: 'bar'
            count.in_subflow
          end
        }.check { count.in_flow }

      flow.trigger_root :insert, foo: 'moo'
      flow.trigger_root :insert, foo: 'bar'
    end
  end
end
