var InstitutionSelect = React.createClass({
  getInitialState: function() {
    return {
      institutions: []
    };
  },

  componentDidMount: function() {
    $.get('/api/institutions', function(result) {
      if (!this.isMounted()) return;

      this.setState(React.addons.update(this.state, {
        institutions: { $set: result.institutions },
        selectedInstitutionUuid: { $set: result.institutions[0].uuid }
      }));

      this.fireInstitutionChanged(result.institutions[0].uuid);
    }.bind(this));
  },

  handleInstitutionChange: function(uuid) {
    this.setState(React.addons.update(this.state, {
      selectedInstitutionUuid: { $set: uuid }
    }));

    this.fireInstitutionChanged(uuid);
  },

  fireInstitutionChanged: function(institutionUuid) {
    this.props.onChange(_.find(this.state.institutions, {uuid: institutionUuid}));
  },

  render: function() {
    if (this.state.institutions.length > 1)
      return (
      <div className="row">
        <div className="col pe-2">
          <label>Institution</label>
        </div>
        <div className="col">
          <Select className="input-large" ref="select"
            value={this.state.selectedInstitutionUuid}
            onChange={this.handleInstitutionChange}
            options={this.state.institutions.map(function(institution) {
              return {value: institution.uuid, label: institution.name};
            })}>
          </Select>
        </div>
      </div>);
    else
      return null;
  },
});
