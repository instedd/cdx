require 'csv'

csv_text = File.read('LoincTableCore.csv')
csv = CSV.parse(csv_text, :headers => true, :encoding => 'ISO-8859-1')
csv.each do |row|
  loinc_code = LoincCode.new
  loinc_code.loinc_number = row["LOINC_NUM"]
  loinc_code.component = row["COMPONENT"]

  if loinc_code.save
    puts "Loinc with code: #{loinc_code.loinc_number} saved"
  end
end

puts "There are now #{LoincCode.count} Loinc Codes"