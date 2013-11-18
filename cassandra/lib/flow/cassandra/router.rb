class Flow::Cassandra::Router
  attr_reader :ring, :wrap_around, :keyspace

  def initialize(keyspace)
    @keyspace = keyspace.to_s

    retrieve_ring
    normalize_ring
    extract_wrap_around
  end

  # TODO: local optimization
  # when target and source on one host
  # we can ignore queue provider,
  # but still need reliability
  def determine_queue(token)
    find_range(token).queue
  end

  def all_queues
    @all_queues ||= full_ring.map(&:queue)
  end

  def local_queues
    @local_queues ||= local_ring.map(&:queue)
  end

  def pull_and_propagate(provider)
    local_queues.each do |it|
      provider.new(it).pull_and_propagate blocking: false
    end
  end

  private

  def local_addresses
    @local_addresses ||= System.get_ifaddrs.values.map {|it| it[:inet_addr] }
  end

  def full_ring
    ring + [wrap_around]
  end

  def local_ring
    full_ring.select do |range|
      local_addresses.include? range.endpoints.first
    end
  end

  def find_range(token)
    ring.find do |range|
      range.start_token > token and token <= range.end_token
    end or wrap_around
  end

  def retrieve_ring
    @ring = Cassandra.new(keyspace, server).ring
  end

  def normalize_ring
    ring.each do |range|
      range.start_token = range.start_token.to_i
      range.end_token = range.end_token.to_i
      range.queue = "#{keyspace}_#{range.start_token}"
    end
  end

  def extract_wrap_around
    candidates = ring.select do |it|
      it.start_token > it.end_token
    end

    raise 'More than one wrap around' if candidates.size > 1
    raise 'Missing wrap around'       if candidates.empty?

    @wrap_around = candidates.first
    ring.delete wrap_around
  end

  def server
    Cassandra::Mapper.server
  end
end
