require 'open3'

# https://github.com/mileszs/wicked_pdf/issues/339
class MultipagePdfRenderer
  def self.combine(documents, options)
    outfile = ::WickedPdf::WickedPdfTempfile.new('multipage_pdf_renderer.pdf')

    tempfiles = documents.each_with_index.map do |doc, index|
      file = ::WickedPdf::WickedPdfTempfile.new("multipage_pdf_doc_#{index}.html")
      file.binmode
      file.write(doc)
      file.rewind
      file
    end

    filepaths = tempfiles.map{ |tf| tf.path.to_s }

    wickedPdf = WickedPdf.new
    binary = wickedPdf.send(:find_wkhtmltopdf_binary_path)
    pdf_options = wickedPdf.send(:parse_options, options)

    command = [binary, '-q']
    command += pdf_options
    filepaths.each { |fp| command << fp }
    command << outfile.path.to_s
    err = Open3.popen3(*command) do |stdin, stdout, stderr|
      stderr.read
    end

    raise "Problem generating multipage pdf: #{err}" if err.present?
    return outfile.read
  ensure
    tempfiles.each(&:close!)
  end
end
