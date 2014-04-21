# TODO: how to replay a broken in the middle request
# in case of uuid subkey with a passed time value?
class Flow::Cassandra::Target < Flow::Action
  include Flow::Cassandra
  attr_reader :mapper, :catalog

  def setup!(mapper)
    if mapper.is_a? Cassandra::Mapper
      mapper.action :publisher, self
      @mapper = mapper
    else
      raise ArgumentError, "bad target: #{mapper}"
    end

    extend_name mapper.table
    build_catalog
    prepend_router
  end

  def propagate(type, data)
    if [:insert, :check].include? type
      mapper.config.before_insert.each {|it| it.call data }
    end

    log = catalog.one data

    unless log
      log = {}
      log.merge! key(data)
      log.merge! subkey(data)

      log[:data]        = mapper.one data
      log[:inserts]     = [log[:data]].compact
      log[:compactions] = 0
    end

    previous = log[:data]

    case type
    when :insert
      log[:inserts] << data
      log[:data] = data

      if previous and previous.keys.any? {|key| not data.keys.include? key }
        mapper.remove previous
      end

      converted_data = mapper.insert data
      propagate_next :insert, converted_data

      catalog.insert log
    when :remove
      remove = Cassandra::Mapper::Data::Remove.new mapper.config, data
      converted_data = remove.return!

      if log[:inserts].include? data
        log[:inserts].delete_at log[:inserts].index(data)
        log[:compactions] += 1

        if previous == data
          mapper.remove data
          new_data = log[:inserts].last

          if new_data
            log[:data] = new_data
            mapper.insert new_data
            propagate_next :remove, converted_data
            catalog.insert log
          else
            propagate_next :remove, converted_data
            catalog.remove log
          end
        else
          propagate_next :remove, converted_data
          catalog.insert log
        end

      else
        propagate_next :remove, converted_data
      end
    when :check
      log_inspect log
      log_inspect mapper.one(data)
      propagate_next :check, data
    else
      raise UnknownType, type
    end
  end

  private

  def select(key_type, data)
    mapper.config.send(key_type).each_with_object({}) do |field, result|
      result[field] = data[field]
    end
  end

  def key(data)
    select :key, data
  end

  def subkey(data)
    select :subkey, data
  end

  def build_catalog
    config = mapper.config
    @catalog = Cassandra::Mapper.new mapper.keyspace_base, name do
      key    *config.key
      subkey *config.subkey
      type :data,        :marshal
      type :inserts,     :marshal
      type :compactions, :integer
    end
  end
end
