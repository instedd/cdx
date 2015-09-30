class ZipSerialize
  def self.dump(x)
    Zlib.deflate(x, 9)
  end

  def self.load(x)
    x.nil? ? nil : Zlib.inflate(x)
  end
end
