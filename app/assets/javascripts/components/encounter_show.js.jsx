var EncounterShow = React.createClass({
  render: function() {
    // TODO: Show institution

    return (
      <div>
        <div className="row">
          <div className="col pe-2">
            <label>Site</label>
          </div>
          <div className="col">
            <p>{this.props.encounter.site.name}</p>
          </div>
        </div>

        <FlexFullRow>
          <PatientCard patient={this.props.encounter.patient} />
        </FlexFullRow>

        <div className="row">
          <div className="col pe-2">
            <label>Diagnosis</label>
          </div>
          <div className="col">
            <AssaysResultList assays={this.props.encounter.assays} />

            <p>{this.props.encounter.observations}</p>
          </div>
        </div>

        <div className="row">
          <div className="col pe-2">
            <label>Samples</label>
          </div>
          <div className="col">
            <SamplesList samples={this.props.encounter.samples} />
          </div>
        </div>

        <div className="row">
          <div className="col">
            <TestResultsList testResults={this.props.encounter.test_results} />
          </div>
        </div>
      </div>
    );
  },

});
