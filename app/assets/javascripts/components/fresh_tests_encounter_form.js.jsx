var FreshTestsEncounterForm = React.createClass({
  getInitialState: function() {
    return {
      encounter: this.props.encounter
    };
  },

  componentWillReceiveProps: function(nextProps) {
    this.setState({encounter: nextProps.encounter});
  },

  render: function() {
    return (
      <div>
        <PatientSelect context={this.props.context} onPatientChanged={this.onPatientChanged} />
      </div>
    );
  },

  onPatientChanged: function(patient) {
    console.log(patient);
  },
});
