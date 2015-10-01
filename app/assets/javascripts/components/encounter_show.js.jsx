var EncounterShow = React.createClass({
  render: function() {
    // TODO: Show institution

    return (
      <div>
        <FlexFullRow>
          <PatientCard patient={this.props.encounter.patient} />
        </FlexFullRow>

        <div className="row">
          <div className="col-p1">
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
