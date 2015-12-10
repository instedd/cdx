var PolicyItemDetail = React.createClass({
  render: function() {
    return (
      <div>
        <label htmlFor="delegable">Delegable</label>
        <input type="checkbox" id="delegable" checked={this.props.statement.delegable} onChange={this.props.toggleDelegable} />
        <label htmlFor="delegable">Users CAN{this.props.statement.delegable ? "" : "NOT"} delegate permissions on this policy</label>
      </div>
    );

  },

});
