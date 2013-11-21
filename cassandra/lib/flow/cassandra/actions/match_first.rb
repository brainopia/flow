class Flow::Cassandra::MatchFirst < Flow::Action
  include Flow::Cassandra
  attr_reader :mapper, :callback, :catalog

  def setup!(mapper, &callback)
    @mapper   = mapper
    @callback = callback

    extend_name mapper.table
    build_catalog
    prepend_router

    secondary_flow = source(mapper).derive do |data|
      data.merge _secondary_: true
    end

    # place secondary_flow before router action
    parents.first.add_parent secondary_flow.action

    # mapper.config.dsl.after_insert do |match|
    #   key    = select(:key, match)
    #   subkey = select(:subkey, match)

    #   records = catalog.get key, start: subkey

    #   records.each do |record|
    #     catalog.remove record
    #     propagate_next :remove, record[:action_result]

    #     record[:action_result] = callback.call record[:action_data], match
    #     record.merge! subkey

    #     catalog.insert record
    #     propagate_next :insert, record[:action_result]
    #   end
    # end

    # mapper.config.dsl.after_remove do |match|
    #   key    = select(:key, match)
    #   subkey = select(:subkey, match)

    #   records = catalog.get key.merge(subkey)
    #   records.each do |record|
    #     catalog.remove record
    #     propagate_next :remove, record[:action_result]
    #     match_first :insert, key, record[:action_data]
    #   end
    # end
  end

  def propagate(type, data)
    key = select(:key, data)

    if key.values.any?(&:nil?)
      propagate_next type, callback.call(data, nil)
    else
      match_first type, key, data
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
