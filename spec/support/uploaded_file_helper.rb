require 'active_support/concern'

module UploadedFileHelper
  extend ActiveSupport::Concern

  def uploaded_file(contents, type, binary = false, &block)
    tempfile = Tempfile.new("uploaded_file")
    begin
      tempfile.write(contents)
      tempfile.rewind
      yield Rack::Test::UploadedFile.new(tempfile, type, binary)
    ensure
      tempfile.close
      tempfile.unlink
    end
  end
end
