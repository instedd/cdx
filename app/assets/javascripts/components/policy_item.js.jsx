var PolicyItem = React.createClass({
  getInitialState: function() {
    return {
      statement: this.props.statement || {type: null, delegable: false, resources: null, actions: []}
    };
  },

  render: function() {
    if(this.state.type == null) {
      return (
        <div>
          <div className="resource-type">New Policy</div>
          <div className="description">Type, resource, and actions are not defined yet</div>
        </div>
      );
    } else {
      return (
        <div>
          <div className="resource-type">POLICY WITH TYPE</div>
          <div className="description">Device, aca, algo esto</div>
        </div>
      );
    }
  },

});
