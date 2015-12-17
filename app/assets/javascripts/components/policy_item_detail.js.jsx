var PolicyItemDetail = React.createClass({
  resourceTypes: [
    {value: 'site', label: 'Site'},
    {value: 'device', label: 'Device'},
    {value: 'testResult', label: 'Test Result'},
    {value: 'encounter', label: 'Encounter'}
  ],

  idFor: function(name) {
    return name + "-" + this.props.index;
  },

  toggleDelegable: function() {
    this.props.updateStatement({delegable: { $apply: function(current) { return !current; } }});
  },

  onResourceTypeChange: function(newValue) {
    this.props.updateStatement({resourceType: { $set: newValue }});
  },

  toggleIncludeSubsites: function() {
    this.props.updateStatement({includeSubsites: { $apply: function(current) { return !current; } }});
  },

  render: function() {
    var statement = this.props.statement;
    return (
      <div>
        <div className="section">
          <span className="section-name">Delegable</span>
          <div className="section-content">
            <input type="checkbox" id={this.idFor("delegable")} checked={statement.delegable} onChange={this.toggleDelegable} />
            <label htmlFor={this.idFor("delegable")}>Users CAN{statement.delegable ? "" : "NOT"} delegate permissions on this policy</label>
          </div>
        </div>
        <div className="section">
          <span className="section-name">Type</span>
          <div className="section-content">
            <CdxSelect items={this.resourceTypes} value={statement.resourceType} onChange={this.onResourceTypeChange} />
            <input type="checkbox" id={this.idFor("includeSubsites")} checked={statement.includeSubsites} onChange={this.toggleIncludeSubsites} />
            <label htmlFor={this.idFor("includeSubsites")}>Include subsites</label>
          </div>
        </div>
      </div>
    );
  },

});
