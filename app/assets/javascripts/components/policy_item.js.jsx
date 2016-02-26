var PolicyItem = React.createClass({
  render: function() {
    var statement = this.props.statement;
    if(statement.resourceType == null) {
      return (
        <div>
          <div className="resource-type">New Policy</div>
          <div className="description">Type, resource, and actions are not defined yet</div>
        </div>
      );
    } else {
      var withSubsites = "";
      if(statement.includeSubsites) {
        if(statement.resourceType == "site") {
          withSubsites = " and subsites";
        } else {
          withSubsites = " at site and subsites";
        }
      }
      var inherits = statement.actions.find(function(action) { return action.id == '*' });
      var description = null;
      if(inherits) {
        description = inherits.label;
      } else {
        var actions = statement.actions.filter(function(action) { return action.resource == statement.resourceType });
        if(actions.length == 0) {
          description = "No actions granted";
        } else {
          description = actions.map(function(action) { return action.label; }).join(", ");
        }
      }
      return (
        <div>
          <div className="resource-type">{statement.resourceType}{withSubsites}</div>
          <div className="description">{description}</div>
        </div>
      );
    }
  },

});
