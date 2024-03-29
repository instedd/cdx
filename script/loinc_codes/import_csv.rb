require 'csv'

csv_text = File.read('script/loinc_codes/LoincTableCore.csv')
csv = CSV.parse(csv_text, :headers => true, :encoding => 'ISO-8859-1')

puts "Start importing Loinc Codes ..."

csv.each do |row|
  loinc_code = LoincCode.new
  loinc_code.loinc_number = row["LOINC_NUM"]
  loinc_code.component = row["COMPONENT"]

  unless LoincCode.exists?(loinc_number: loinc_code.loinc_number)
    if loinc_code.save
      puts "Loinc with code: #{loinc_code.loinc_number} saved"
    end
  end
end

puts "There are now #{LoincCode.count} Loinc Codes"
