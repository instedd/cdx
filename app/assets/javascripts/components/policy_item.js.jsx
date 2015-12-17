var PolicyItem = React.createClass({
  render: function() {
    if(this.props.statement.resourceType == null) {
      return (
        <div>
          <div className="resource-type">New Policy</div>
          <div className="description">Type, resource, and actions are not defined yet</div>
        </div>
      );
    } else {
      return (
        <div>
          <div className="resource-type">{this.props.statement.resourceType}</div>
          <div className="description">Device, aca, algo esto</div>
        </div>
      );
    }
  },

});
