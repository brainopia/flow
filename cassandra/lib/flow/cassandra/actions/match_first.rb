class Flow::Cassandra::MatchFirst < Flow::Action
  include Flow::Cassandra
  attr_reader :mapper, :callback, :catalog

  def setup!(mapper, &callback)
    @mapper   = mapper
    @callback = callback

    extend_name mapper.table
    build_catalog
    prepend_router

    secondary_flow = empty_flow
      .cassandra_source(mapper)
      .copy_location(self)
      .derive {|data| data.merge _secondary_: true }
      .copy_location(self)

    # place secondary_flow before router action
    # we use one-way relation to signify
    # that secondary flow is not a root action
    secondary_flow.action.add_child parents.first
  end

  def propagate(type, data)
    key = select(:key, data)

    if data.delete :_secondary_
      case type
      when :insert
        subkey = select(:subkey, data)
        records = catalog.get key, start: subkey

        records.each do |record|
          catalog.remove record
          propagate_next :remove, record[:action_result]

          record[:action_result] = callback.call record[:action_data], data
          record.merge! subkey

          catalog.insert record
          propagate_next :insert, record[:action_result]
        end
      when :remove
        subkey = select(:subkey, data)
        records = catalog.get key.merge(subkey)

        records.each do |record|
          catalog.remove record
          propagate_next :remove, record[:action_result]
          match_first :insert, key, record[:action_data]
        end
      when :check
      else
        raise UnknownType, type
      end
    else
      if key.values.any?(&:nil?)
        propagate_next type, callback.call(data, nil)
      else
        match_first type, key, data
      end
    end
  end

  private

  def match_first(type, key, data)
    case type
    when :insert
      matched = mapper.one key
      subkey  = matched ? select(:subkey, matched) : max_subkey
      result  = callback.call data, matched

      catalog_record = key
      catalog_record.merge! subkey
      catalog_record.merge! action_data: data, action_result: result
      catalog.insert catalog_record
    when :remove
      all = catalog.get(key)
      found = all.find {|it| it[:action_data] == data }

      if found
        result = found[:action_result]
        catalog.remove found
      end
    when :check
      all = catalog.get(key)
      found = all.find {|it| it[:action_data] == data }

      result = found[:action_result] if found

      log_inspect key
      log_inspect found
      log_inspect all
    end

    propagate_next type, result
  end

  def select(key_type, data)
    mapper.config.send(key_type).each_with_object({}) do |field, result|
      result[field] = data[field]
    end
  end

  def key(data)
    select :key, data
  end

  def max_subkey
    mapper.config.subkey.each_with_object({}) do |field, data|
      type        = mapper.config.types[field]
      data[field] = Cassandra::Mapper::Convert.max type
    end
  end

  def build_catalog
    config = mapper.config
    @catalog = Cassandra::Mapper.new keyspace, name do
      key *config.key
      subkey *config.subkey, :uuid
      type :action_data, :marshal
      type :action_result, :marshal
      type :uuid, :uuid

      config.subkey.each do |field|
        type field, config.types[field]
      end

      before_insert do |data|
        data[:uuid] ||= Time.now
      end
    end
  end
end
