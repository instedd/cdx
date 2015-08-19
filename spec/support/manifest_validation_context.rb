shared_context "skip manifest validation", validate_manifest: false do

  before(:each) do
    allow_any_instance_of(Manifest).to receive(:manifest_validation)
  end

end
