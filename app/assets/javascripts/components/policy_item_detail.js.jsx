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

  render: function() {
    return (
      <div>
        <div>
          <label htmlFor={this.idFor("delegable")}>Delegable</label>
          <input type="checkbox" id={this.idFor("delegable")} checked={this.props.statement.delegable} onChange={this.props.toggleDelegable} />
          <label htmlFor={this.idFor("delegable")}>Users CAN{this.props.statement.delegable ? "" : "NOT"} delegate permissions on this policy</label>
        </div>
        <div>
          <label>Type</label>
          <CdxSelect items={this.resourceTypes} value={this.props.statement.resourceType} onChange={this.props.onResourceTypeChange} />
          <input type="checkbox" id={this.idFor("includeSubsites")} checked={this.props.statement.includeSubsites} onChange={this.props.toggleIncludeSubsites} />
          <label htmlFor={this.idFor("includeSubsites")}>Include subsites</label>
        </div>
      </div>
    );
  },

});
