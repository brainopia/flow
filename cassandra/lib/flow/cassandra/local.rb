module Flow::Cassandra::Local
  extend self

  def addresses
    @local_addresses ||= begin
      if RUBY_VERSION['2.1']
        Socket.getifaddrs.map(&:addr).compact.select(&:ip?).map(&:ip_address)
      else
        require 'system/getifaddrs'
        System.get_ifaddrs.values.map {|it| it[:inet_addr] }
      end
    end
  end
end
