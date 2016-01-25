var PolicyDefinitionField = React.createClass({
  render: function() {
    var statements = this.props.statements.map(function(statement) {
      var result = {
        delegable: statement.delegable,
        action: [],
        resource: [],
        except: []
      };

      if(statement.actions.findIndex(function(action) { return action.id == "*" }) >=0) {
        result.action = "*";
      } else {
        result.action = statement.actions
          .filter(function(action) { return action.resource == statement.resourceType })
          .map(function(action) { return action.id });
      }

      if(statement.statementType) {
        var _resource_to_policy_identifier = function(resource) {
          if(resource.type == statement.resourceType) {
            return resource.type + "/" + resource.id;
          } else {
            return statement.resourceType + "?" + resource.type + "=" + resource.id;
          }
        };

        if(statement.statementType == "all") {
          result.resource = statement.resourceType;
        } else {
          var statement_resources = statement.resourceList[statement.statementType].map(_resource_to_policy_identifier);

          if(statement.statementType == "except") {
            result.resource = statement.resourceType;
            result.except = statement_resources;
          } else {
            result.resource = statement_resources;
          }
        }
      }

      return result;
    });
    var policy = {statement: statements};

    return (
      <div>
        <input type="hidden" value={JSON.stringify(policy)} name={this.props.name} />
      </div>
    )
  }
});
