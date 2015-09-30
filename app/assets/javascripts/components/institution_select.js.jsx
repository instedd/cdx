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

  handleInstitutionChange: function(event) {
    this.setState(React.addons.update(this.state, {
      selectedInstitutionUuid: { $set: event.target.value }
    }));

    this.fireInstitutionChanged(event.target.value);
  },

  fireInstitutionChanged: function(institutionUuid) {
    this.props.onChange(_.find(this.state.institutions, {uuid: institutionUuid}));
  },

  render: function() {
    if (this.state.institutions.length > 1)
      return (
      <div className="row">
        <div className="col pe-2">
          <label className="control-label">Institution</label>
          <select ref="select" value={this.state.selectedInstitutionUuid} onChange={this.handleInstitutionChange}>
          {this.state.institutions.map(function(institution) {
             return <option key={institution.uuid} value={institution.uuid}>{institution.name}</option>;
          })}
          </select>
        </div>
      </div>);
    else
      return null;
  },
});
