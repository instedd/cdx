var PolicyDefinition = React.createClass({
  getInitialState: function() {
    return {
      statements: this.policyDefinitionStatements(this.props),
      activeTab: 0
    };
  },

  policyDefinitionStatements: function(props) {
    var definition = props.definition;
    if(definition == null) {
      return [];
    }
    definition = JSON.parse(definition);
    var statements = definition.statement.map(function(statement) {
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
        resources = statement.except;
      } else {
        if(Array.isArray(statement.resource) && (statement.resource.length > 0)) {
          resources = statement.resource;
          if(_resourceComponents(resources[0]).thisResourceId) {
            statementType = 'only';
          } else {
            statementType = 'all';
          }
        }
      }

      var _hydratateResourceAndCheckType = function(resources, resourceKey) {
        var components = _resourceComponents(resourceKey);

        if(!resourceType) {
          resourceType = components.policyResourceType;
        }
        if(components.policyResourceType != resourceType) {
          // FIXME - show this warnings to the user
          console.warn("Resource type " + components.policyResourceType + " doesn't match previous resource's type " + resourceType +
              " - the control may not work OK");
        }
        return resources[resourceKey];
      }

      if(statementType == "only" || statementType == "except") {
        resourceList[statementType] = resources.map(_hydratateResourceAndCheckType.bind(this, props.resources));
      }

      var _hydratateAction = function(actions, action) {
        var components = action.split(":");
        return actions[components[0]][components[1]];
      }

      var actions = null;
      if (statement.action == '*') {
        actions = [{id: '*', label: 'Inherit permissions from granter', value: '*'}];
      } else {
        actions = statement.action.map(_hydratateAction.bind(this, props.actions));
      }

      return {
        delegable: statement.delegable == true,
        includeSubsites: false, // TODO: still unsupported in policies definitions
        actions: actions,
        resourceList: resourceList,
        resourceType: resourceType,
        resources: statementType
      };
    });

    return statements;
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
