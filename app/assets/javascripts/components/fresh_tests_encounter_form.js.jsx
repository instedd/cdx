var FreshTestsEncounterForm = React.createClass(_.merge({
  render: function() {
    return (
      <div>
        <PatientSelect patient={this.state.encounter.patient} context={this.props.context} onPatientChanged={this.onPatientChanged} />

        <div className="row">
          <div className="col pe-2">
            <label>Samples</label>
          </div>
          <div className="col">
            <NewSamplesList samples={this.state.encounter.new_samples} onRemoveSample={this.removeNewSample} />

            <p>
              <a className="btn-add-link" href='#' onClick={this.addNewSamples}>
                <span className="icon-circle-plus icon-blue"></span> Add sample
              </a>
            </p>
          </div>
        </div>

        <hr/>

        <FlexFullRow>
          <button type="button" className="btn-primary" onClick={this.save}>Save</button>
          <a href="/encounters/new_index" className="btn btn-link">Cancel</a>
        </FlexFullRow>

        <Modal ref="addNewSamplesModal">
          <h1>
            <a href="#" className="modal-back" onClick={this.closeAddNewSamplesModal}></a>
            Add sample
          </h1>

          <p><input type="text" className="input-block" placeholder="Sample ID" ref="manualSampleEntry" /></p>
          <p><button type="button" className="btn-primary pull-right" onClick={this.validateAndSetManualEntry}>OK</button></p>
        </Modal>

      </div>
    );
  },

  onPatientChanged: function(patient) {
    this.setState(React.addons.update(this.state, {
      encounter : { patient: { $set : patient } },
    }));
  },
}, BaseEncounterForm));
