var PolicyDefinition = React.createClass({
  getInitialState: function() {
    return {
      statements: this.policyDefinitionStatements(this.props),
      activeTab: 0
    };
  },

  emptyPolicy: { delegable: false, resourceType: null, includeSubsites: true, actions: [], resourceList: {'except': [], 'only': []} },

  policyDefinitionStatements: function(props) {
    var definition = props.definition;
    if(definition == null) {
      return [this.emptyPolicy];
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
        } else if(statement.resource && statement.resource.length > 0) {
          statementType = 'all';
          resources = [statement.resource];
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

      switch (statementType) {
        case "only":
        case "except":
          resourceList[statementType] = resources.map(_hydratateResourceAndCheckType.bind(this, props.resources));
          break;
        case "all":
          resourceType = resources[0];
          break;
        default:

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
        includeSubsites: true, // TODO: still unsupported in policies definitions
        actions: actions,
        resourceList: resourceList,
        resourceType: resourceType,
        resources: statementType
      };
    });

    if(statements.length == 0) {
      return [this.emptyPolicy];
    } else {
      return statements;
    }
  },

  newPolicy: function() {
    this.setState(React.addons.update(this.state, {
      statements: { $push: [this.emptyPolicy] },
      activeTab: { $set: this.state.statements.length } // the new statement isn't on the array yet
    }));
  },

  updateStatement: function(index, changes) {
    this.setState(React.addons.update(this.state, {
      statements: {
        // TODO - check non-Chrome browsers compatibility (keyword: ES2015 dynamic indexes/keys)
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
              <li><span onClick={this.newPolicy} href="javascript:">Add policy</span></li>
            </ul>
            {this.state.statements.map(function(statement, index) {
              var tabClass = "tabs-content" + (this.state.activeTab === index ? " selected" : "");
              return (<div className={tabClass} key={index}><PolicyItemDetail statement={statement} index={index} updateStatement={this.updateStatement.bind(this, index)} actions={this.props.actions} resourceTypes={this.props.resourceTypes} context={this.props.context} /></div>);
            }.bind(this))}
          </div>
        </div>

      </div>
    )
  }
});
