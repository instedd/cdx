require 'spec_helper'

describe SamplesReport do
  let!(:institution) { Institution.make }
  let!(:site) { Site.make(institution: institution) }

  before do
    @box = Box.make!(:lob_lod, institution: institution, purpose: "LOD")
    @samples_report = SamplesReport.create(
      institution: institution,
      samples_report_samples: @box.samples.map { |s| SamplesReportSample.new(sample: s) },
      name: "Sample"
    )
  end

  it 'calculates LOD and LOB correctly' do

@samples_report.calculate_lod_and_lob
expect(@samples_report.lod).to eq(17.652)
expect(@samples_report.lob).to eq(14.443)

  end
end
