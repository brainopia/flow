class Flow::Cassandra::MatchTime < Flow::Action
  include Flow::Cassandra
  attr_reader :mapper, :callback, :catalog,
              :source_field, :matched_field,
              :interval

  # TIME_STEP instead of (slice: :before/after) because of uuid
  TIME_STEP = 0.001

  def setup!(mapper, options={}, &callback)
    @mapper        = mapper
    @callback      = callback
    @match_after   = options[:after]
    @matched_field = mapper.config.subkey.first
    @source_field  = case
      when options[:source]
        options[:source]
      when source
        source.config.subkey.first
      else
        @matched_field
      end

    if options[:interval]
      @interval = (options[:interval] + TIME_STEP) * (match_after? ? 1 : -1)
    end

    extend_name mapper.table
    extend_name source_field.to_s
    extend_name matched_field.to_s
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
      matched_time = data[matched_field]
      records = query_catalog key, matched_time

      case type
      when :insert
        unless interval
          records.select! do |it|
            sign = match_after? ? :> : :<
            not it[:matched_time] or it[:matched_time].send(sign, matched_time)
          end
        end

        records.each do |record|
          prepare = { result: record[:action_result], time: record[:source_time] }
          prepare[:match] = data unless interval
          match_time :insert, key, record[:action_data], prepare
        end
      when :remove
        unless interval
          records.select! {|it| it[:matched_time].to_i == matched_time.to_i }
        end

        records.each do |record|
          prepare = { result: record[:action_result], time: record[:source_time] }
          match_time :insert, key, record[:action_data], prepare
        end
      when :check
        unless interval
          records.select! {|it| it[:matched_time].to_i == matched_time.to_i }
        end

        log_inspect :secondary
        log_inspect data
        log_inspect records

        records.each do |record|
          prepare = { result: record[:action_result], time: record[:source_time] }
          match_time :check, key, record[:action_data], prepare
        end
      else
        raise UnknownType, type
      end
    else
      if key.values.any?(&:nil?)
        propagate_next type, callback.call(data, nil)
      else
        match_time type, key, data
      end
    end
  end

  private

  def match_time(type, key, data, prepared_data={})
    source_time = prepared_data[:time] || data[source_field]
    error! "missing :#{source_field} in #{data.inspect}" unless source_time

    catalog.keyspace.batch do
      case type
      when :insert
        if prepared_data[:match]
          matched = prepared_data[:match]
        else
          query = if match_after?
              { start: { matched_field => source_time }}
            else
              # slice :after in reverse means to match including current record
              { reversed: true, start: { matched_field => source_time, slice: :after }}
            end
          if interval
            query[:finish] = { matched_field => source_time + interval }
            matched = mapper.get key, query
          else
            matched = mapper.one key, query
          end

          if interval and not match_after?
            matched.reverse!
          end
        end

        result = callback.call data, matched

        if matched and not interval
          matched_time = matched[matched_field]
        end

        catalog_record = key
        catalog_record.merge! \
          action_data:    data,
          action_result:  result,
          matched_time:   matched_time,
          source_time:    source_time
        catalog.insert catalog_record
      when :remove
        all = catalog.get key
        found = if data[:_id]
          all.find {|it| it[:action_data][:_id] == data[:_id] }
        else
          all.find {|it| it[:action_data] == data }
        end

        if found
          result = found[:action_result]
          catalog.remove found
        end
      when :check
        all = catalog.get key
        found = all.find {|it| it[:action_data] == data }

        log_inspect key
        log_inspect found
        log_inspect all

        if found
          result = found[:action_result]
        end
      end

      previous_result = prepared_data.fetch(:result, false)
      if result != previous_result
        if previous_result and type != :check
          propagate_next :remove, previous_result 
        end

        propagate_next type, result
      end
    end
  end

  def build_catalog
    config = mapper.config
    @catalog = Cassandra::Mapper.new keyspace, name do
      key *config.key
      subkey :source_time
      type :action_data,   :marshal
      type :action_result, :marshal
      type :source_time,   :uuid
      type :matched_time,  :time
    end
  end

  def select(key_type, data)
    mapper.config.send(key_type).each_with_object({}) do |field, result|
      result[field] = data[field]
    end
  end

  def error!(text, error=ArgumentError)
    raise error, <<-ERROR
      #{text}
      from #{location}
      parents #{parents.map(&:location).join(', ')}
    ERROR
  end

  def match_after?
    @match_after
  end

  def rounded_time(time)
    Time.at((time.to_f * 1000).to_i / 1000.0)
  end

  def key(data)
    select :key, data
  end

  def query_catalog(key, time)
    if match_after?
      query = { finish: { source_time: time + TIME_STEP }}
      if interval
        query[:start] = { source_time: time - interval }
      end
    else
      query = { start: { source_time: time - TIME_STEP }}
      if interval
        query[:finish] = { source_time: time - interval }
      end
    end

    catalog.get key, query
  end

  def source
    action = self
    loop do
      action = action.parents.first
      break unless action
      if action.respond_to? :mapper
        break action.mapper
      end
    end
  end
end
