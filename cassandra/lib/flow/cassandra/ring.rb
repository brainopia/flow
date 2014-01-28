class Flow::Cassandra::Ring
  attr_reader :ranges, :monotonic_ranges,
              :wrap_around, :keyspace

  def initialize(keyspace)
    @keyspace = keyspace.to_s

    retrieve_ranges
    normalize_ranges
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
    @all_queues ||= ranges.map(&:queue)
  end

  def local_queues
    @local_queues ||= local_ranges.map(&:queue)
  end

  private

  def local_ranges
    ranges.select do |range|
      Flow::Cassandra::Local.addresses.include? range.endpoints.first
    end
  end

  def find_range(token)
    monotonic_ranges.find do |range|
      range.start_token < token and token <= range.end_token
    end or wrap_around
  end

  def retrieve_ranges
    @ranges = Cassandra.new(keyspace, server).ring
  end

  def normalize_ranges
    ranges.each do |range|
      range.start_token = range.start_token.to_i
      range.end_token = range.end_token.to_i
      range.queue = Floq["#{keyspace}_#{range.start_token}", :singular]
    end
  end

  def extract_wrap_around
    candidates = ranges.select do |it|
      it.start_token > it.end_token
    end

    raise 'More than one wrap around' if candidates.size > 1
    raise 'Missing wrap around'       if candidates.empty?

    @wrap_around = candidates.first
    @monotonic_ranges = ranges - [ wrap_around ]
  end

  def server
    Cassandra::Mapper.server
  end
end
