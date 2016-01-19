var PolicyDefinition = React.createClass({
  getInitialState: function() {
    return {
      statements: this.policyDefinitionStatements(this.props.definition, this.props.actions),
      activeTab: 0
    };
  },

  policyDefinitionStatements: function(definition, actionsDefinitions) {
    if(definition == null) {
      return [];
    }
    definition = JSON.parse(definition);
    return definition.statement.map(function(statement) {
      var resourceList = {
        'except': [],
        'only': []
      }

      var statementType = null;
      var resources = null;
      var resourceType = null;

      var _resourceComponents = function(resource) {
        var parts;
        if(parts = resource.match(/(.*)\?(.*)\=(.*)/)) {
          // policyType?resourceType=resourceId
          return {
            policyResourceType: parts[1],
            thisResourceType: parts[2],
            thisResourceId: parts[3]
          }
        } else if(parts = resource.match(/(.*)\/(.*)/)) {
          // resourceType/resourceId
          return {
            policyResourceType: parts[1],
            thisResourceType: parts[1],
            thisResourceId: parts[2]
          }
        } else {
          // resourceType - ie, the whole class
          return {
            policyResourceType: resource,
            thisResourceType: resource
          }
        }
      }

      if(Array.isArray(statement.except) && (statement.except.length > 0)) {
        statementType = 'except';
        resources = statement.except.map(function(resource) {
          var components = _resourceComponents(resource);

          if(!resourceType) {
            resourceType = components.policyResourceType;
          }
          if(components.policyResourceType != resourceType) {
            // FIXME - show this warnings to the user
            console.warn("Resource type " + components.policyResourceType + " doesn't match previous resource's type " + resourceType +
                " - the control may not work OK");
          }
          return {type: components.thisResourceType, id: components.thisResourceId};
        });
      } else {
        if(Array.isArray(statement.resource) && (statement.resource.length > 0)) {
          resources = statement.resource.map(function(resource) {
            var components = _resourceComponents(resource);

            if(!resourceType) {
              resourceType = components.policyResourceType;
            }
            if(components.policyResourceType != resourceType) {
              // FIXME - show this warnings to the user
              console.warn("Resource type " + components.policyResourceType + " doesn't match previous resource's type " + resourceType +
                  " - the control may not work OK");
            }

            var result = { type: components.thisResourceType };
            if(components.thisResourceId) {
              statementType = 'only';
              result.id = components.thisResourceId;
            } else {
              statementType = 'all';
            }
            return result;
          });
        }
      }

      var _hydratateResources = function(resources) {
        // FIXME: ask the server for the full resource objects
        return resources;
      }

      if(statementType == "only" || statementType == "except") {
        resourceList[statementType] = _hydratateResources(resources);
      }

      var _hydratateAction = function(actions, action) {
        if(action == "*") {
          return {id: '*', label: 'Inherit permissions from granter', value: '*'};
        }
        var components = action.split(":");
        return actions[components[0]][components[1]];
      }

      return {
        delegable: statement.delegable == true,
        includeSubsites: false, // TODO: still unsupported in policies definitions
        actions: statement.action.map(_hydratateAction.bind(this, actionsDefinitions)),
        resourceList: resourceList,
        resourceType: resourceType,
        resources: statementType
      };
    });
  },

  newPolicy: function() {
    this.setState(React.addons.update(this.state, {
      statements: { $push: [{ delegable: false, resourceType: null, includeSubsites: false, actions: [], resourceList: {'except': [], 'only': []} }] },
      activeTab: { $set: this.state.statements.length } // the new statement isn't on the array yet
    }));
  },

  updateStatement: function(index, changes) {
    this.setState(React.addons.update(this.state, {
      statements: {
        [index]: changes
      }
    }))
  },

  setActiveTab: function(index) {
    this.setState(React.addons.update(this.state, {
      activeTab: { $set: index }
    }));
  },

  render: function() {
    return (
      <div>
        <PolicyDefinitionField name="role[definition]" statements={this.state.statements} />
        <div className="left-column">
          <div className="tabs">
            <ul className="tabs-header">
              {this.state.statements.map(function(statement, index){
                var selectedClass = this.state.activeTab == index ? "selected" : "";
                return <li key={index} onClick={this.setActiveTab.bind(this,index)} className={selectedClass}><PolicyItem statement={statement} /></li>;
              }.bind(this))}
              <li><a onClick={this.newPolicy} href="javascript:">Add policy</a></li>
            </ul>
            {this.state.statements.map(function(statement, index) {
              var tabClass = "tabs-content" + (this.state.activeTab === index ? " selected" : "");
              return (<div className={tabClass} key={index}><PolicyItemDetail statement={statement} index={index} updateStatement={this.updateStatement.bind(this, index)} actions={this.props.actions} context={this.props.context} /></div>);
            }.bind(this))}
          </div>
        </div>

      </div>
    )
  }
});
