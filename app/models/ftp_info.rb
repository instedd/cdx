class FtpInfo < Struct.new(:hostname, :port, :directory, :username, :password, :passive)
  def self.new(*args)
    if args.length == 1 && args[0].is_a?(Hash)
      unexpected = args[0].keys - self.members
      fail "Unexpected keys: #{unexpected.join(', ')}" if unexpected.any?
      super(*self.members.map { |m| args[0][m] })
    else
      super
    end
  end

  def self.mapping(prefix)
    self.members.map { |m| ["#{prefix}#{m}", m] }
  end
end
