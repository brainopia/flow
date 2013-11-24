class Flow::Cassandra::Flag < Flow::Action
  include Flow::Cassandra
  attr_reader :flag, :scope, :condition, :catalog

  LIMIT_HISTORY = 10

  def setup!(name, scope, &condition)
    @flag      = name or raise ArgumentError
    @scope     = Array scope
    @condition = condition

    extend_name @flag
    extend_name @scope.join('_')
    build_catalog
    prepend_router
  end

  def transform(type, data)
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
      catalog.insert scope: scope_value, data: data, all: all
      data = data.dup
      data[flag] = true
    else
      catalog.insert scope: scope_value, data: previous, all: all
    end

    if reflag and previous
      propagate_next :remove, previous.merge(flag => true)
      propagate_next :insert, previous
    end

    data
  end

  def remove(data, scope_value, previous, all)
    if all.delete data
      if data == previous
        data = data.dup
        data[flag] = true

        new_data = all.sort {|a,b| condition.call(a,b) ? -1 : 1 }.first
        if new_data
          propagate_next :remove, new_data
          catalog.insert scope: scope_value, data: new_data, all: all
          propagate_next :insert, new_data.merge(flag => true)
        else
          catalog.remove scope: scope_value
        end
      else
        catalog.insert scope: scope_value, data: previous, all: all
      end
    end

    data
  end

  def check(data, scope_value, previous, all)
    log_inspect scope_value
    log_inspect all

    if data == previous
      data = data.merge flag => true
    end

    data
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
