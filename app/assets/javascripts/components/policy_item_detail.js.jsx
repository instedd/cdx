var PolicyItemDetail = React.createClass({
  resourceTypes: [
    {value: 'site', label: 'Site'},
    {value: 'device', label: 'Device'},
    {value: 'testResult', label: 'Test Result'},
    {value: 'encounter', label: 'Encounter'}
  ],
  render: function() {
    return (
      <div>
        <div>
          <label htmlFor="delegable">Delegable</label>
          <input type="checkbox" id="delegable" checked={this.props.statement.delegable} onChange={this.props.toggleDelegable} />
          <label htmlFor="delegable">Users CAN{this.props.statement.delegable ? "" : "NOT"} delegate permissions on this policy</label>
        </div>
        <div>
          <label>Type</label>
          <CdxSelect items={this.resourceTypes} value={this.props.statement.resourceType} onChange={this.props.onResourceTypeChange} />
        </div>
      </div>
    );
  },

});
