var FreshTestsEncounterForm = React.createClass(_.merge({
  render: function() {
    return (
      <div>
        <PatientSelect context={this.props.context} onPatientChanged={this.onPatientChanged} />

        <div className="row">
          <div className="col pe-2">
            <label>Samples</label>
          </div>
          <div className="col">
            <NewSamplesList samples={this.state.encounter.new_samples} onRemoveSample={this.removeNewSample} />

            <p>
              <a className="btn-href" href='#' onClick={this.addNewSamples}>
                <span className="icon-add"></span> Add sample
              </a>
            </p>
          </div>
        </div>

        <hr/>

        <FlexFullRow>
          <button type="button" className="btn-primary" onClick={this.save}>Save</button>
          <a href="/encounters/new_index" className="btn btn-link">Cancel</a>
        </FlexFullRow>

      </div>
    );
  },

  onPatientChanged: function(patient) {
    this.setState(React.addons.update(this.state, {
      encounter : { patient: { $set : patient } },
    }));
  },
}, BaseEncounterForm));
