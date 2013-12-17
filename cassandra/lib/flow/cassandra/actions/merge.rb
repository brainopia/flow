class Flow::Cassandra::Merge < Flow::Action
  include Flow::Cassandra
  attr_reader :scope, :callback, :catalog

  FIRST_BACKUP = 4
  LAST_BACKUP  = 6
  LIMIT_BACKUP = FIRST_BACKUP + LAST_BACKUP

  def setup!(scope, &callback)
    @scope    = Array scope
    @callback = callback

    extend_name @scope.join('_')
    build_catalog
    prepend_router
  end

  def propagate(type, data)
    scope_value = scope_value_for data

    record   = catalog.one(scope: scope_value) || {}
    all      = record[:all] || []
    previous = record[:data]

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

    if all.size >= 2*LIMIT_BACKUP
      all = all.first(FIRST_BACKUP) + all.last(LAST_BACKUP)
    end

    update = callback.call data, previous
    catalog.insert scope: scope_value, data: update, all: all

    if previous != update
      propagate_next :remove, previous
      propagate_next :insert, update
    end
  end

  def remove(data, scope_value, previous, all)
    return unless all.index data

    all.delete_at all.index(data)
    update = all.inject(nil) {|previous, it| callback.call(it, previous) }

    if all.empty?
      catalog.remove scope: scope_value
    else
      catalog.insert scope: scope_value, data: update, all: all
    end

    if previous != update
      propagate_next :remove, previous
      propagate_next :insert, update
    end
  end

  def check(data, scope_value, previous, all)
    log_inspect scope_value
    log_inspect all
    propagate_next :check, previous
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
