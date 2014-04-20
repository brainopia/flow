class Flow::Cassandra::Flag < Flow::Action
  include Flow::Cassandra
  attr_reader :flag, :scope, :condition, :catalog

  LIMIT_HISTORY = 50

  def setup!(name, scope, &condition)
    @flag      = name or raise ArgumentError
    @scope     = Array scope
    @condition = condition

    extend_name @flag
    extend_name @scope.join('_')
    build_catalog
    prepend_router
  end

  def propagate(type, data)
    scope_value = scope_value_for data

    record   = catalog.one(scope: scope_value) || {}
    previous = record[:data]
    all      = record[:all] || []

    case type
    when :insert
      insert data, scope_value, previous, all
    when :remove
      remove data, scope_value, previous, all
    when :check
      check data, scope_value, previous, all
    else
      raise UnknownType, type
    end
  end

  private

  def insert(data, scope_value, previous, all)
    all << data
    reflag = !previous || condition.call(data, previous)

    if all.size >= 2*LIMIT_HISTORY
      all = all.sort {|a,b| condition.call(a,b) ? -1 : 1 }.first(LIMIT_HISTORY)
    end

    if reflag
      flagged_data = data.merge flag => true
    end

    if reflag and previous
      propagate_next :remove, previous.merge(flag => true)
      propagate_next :insert, previous
    end

    if reflag
      propagate_next :insert, flagged_data
      catalog.insert scope: scope_value, data: data, all: all
    else
      propagate_next :insert, data
      catalog.insert scope: scope_value, data: previous, all: all
    end
  end

  def remove(data, scope_value, previous, all)
    return unless all.index data
    all.delete_at all.index(data)

    if data == previous
      flagged_data = data.merge flag => true
      propagate_next :remove, flagged_data

      new_data = all.sort {|a,b| condition.call(a,b) ? -1 : 1 }.first

      if new_data
        propagate_next :remove, new_data
        propagate_next :insert, new_data.merge(flag => true)
        catalog.insert scope: scope_value, data: new_data, all: all
      else
        catalog.remove scope: scope_value
      end
    else
      propagate_next :remove, data
      catalog.insert scope: scope_value, data: previous, all: all
    end
  end

  def check(data, scope_value, previous, all)
    log_inspect scope_value
    log_inspect all

    if data == previous
      data = data.merge flag => true
    end

    propagate_next :check, data
  end

  def build_catalog
    @catalog = Cassandra::Mapper.new keyspace, name do
      key  :scope
      type :data, :marshal
      type :all,  :marshal
    end
  end

  def key(data)
    { scope: scope_value_for(data) }
  end
end
