var EncounterNew = React.createClass({
  getInitialState: function() {
    return {encounter: {
      institution: null,
      patient: null,
      samples: [],
      test_results: [],
      assays: [],
      observations: ''
    }};
  },

  setInstitution: function(institution) {
    this.setState(React.addons.update(this.state, {
      encounter: {
        institution: { $set: institution },
        patient: { $set: null },
        samples: { $set: [] },
        test_results: { $set: [] },
        assays: { $set: [] },
        observations: { $set: '' }
      }
    }));
  },

  render: function() {
    var institutionSelect = <InstitutionSelect onChange={this.setInstitution} url="/encounters/institutions"/>;

    if (this.state.encounter.institution == null)
      return (<div>{institutionSelect}</div>);

    return (
      <div>
        {institutionSelect}

        <EncounterForm encounter={this.state.encounter} />
      </div>
    );
  },

});
