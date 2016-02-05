var PolicyItemDetail = React.createClass({
  idFor: function(name) {
    return name + "-" + this.props.index;
  },

  toggleDelegable: function() {
    this.props.updateStatement({delegable: { $apply: function(current) { return !current; } }});
  },

  onResourceTypeChange: function(newValue) {
    this.props.updateStatement({resourceType: { $set: newValue }});
  },

  toggleIncludeSubsites: function() {
    this.props.updateStatement({includeSubsites: { $apply: function(current) { return !current; } }});
  },

  onStatementTypeChange: function(selected) {
    this.props.updateStatement({statementType: { $set: selected}});
  },

  toggleAction: function(action) {
    this.props.updateStatement({
      actions: {
        $apply: (function(actions) {
          actions = actions.slice(); // clone the list - so we don't modify the original one
          var actionIndex = actions.findIndex(function(anAction) { return anAction.id == action.id });
          if(actionIndex < 0) {
            actions.push(action);
          } else {
            actions.splice(actionIndex, 1);
          }
          return actions;
        }).bind(this)
      }
    });
  },

  statementHasAction: function(statement, action) {
    return statement.actions.find(function(anAction) { return anAction.id == action.id });
  },

  removeResourceAtIndex: function(resourceIndex) {
    this.props.updateStatement({resourceList: {[this.props.statement.statementType] : {$splice: [[resourceIndex, 1]]} } })
  },

  addResource: function(resource) {
    if(this.props.statement.resourceList[this.props.statement.statementType].findIndex(function(aResource) {
      return aResource.uuid == resource.uuid;
    }) < 0) {
      this.props.updateStatement({resourceList: {[this.props.statement.statementType] : {$push: [resource]}}})
    }
  },

  resourcesLabel: function() {
    var currentResourceType = this.props.resourceTypes.find((function(resourceType) { return resourceType.value == this.props.statement.resourceType }).bind(this));
    return (currentResourceType.label + "s").toLowerCase();
  },

  render: function() {
    var statement = this.props.statement;
    var resourcesList = {
      "except": <div className="without-statement-type-except-list" />,
      "only": <div className="without-statement-type-only-list" />
    }
    var ifResourceTypeSelected = <div className="without-resource-type" />;
    if(statement.resourceType != null) {
      // FIXME: filter resources for other types - ie, 'site'
      if(['device', 'testResult', 'encounter'].includes(statement.resourceType)) {
        // TODO: replace DeviceList with OptionList
        resourcesList[statement.statementType] = <div className={"with-statement-type-" + statement.statementType + "-list"}><DeviceList devices={statement.resourceList[statement.statementType]} addDevice={this.addResource} removeDevice={this.removeResourceAtIndex} context={this.props.context} isException={statement.statementType == 'except'} /></div>;
      }

      var actions = this.props.actions[statement.resourceType];
      var resourcesLabel = this.resourcesLabel();

      ifResourceTypeSelected = <div className="with-resource-type">
        <div className="row section">
          <div className="col px-1">
            <label className="section-name">Resources</label>
          </div>
          <div className="col">
            <div className="section-content">
              <input type="radio" name="statementType" value="all" id={this.idFor("statement-type-all")} checked={statement.statementType == 'all'} onChange={this.onStatementTypeChange.bind(this, 'all')} />
              <label htmlFor={this.idFor("statement-type-all")}>All {resourcesLabel}</label>
              <input type="radio" name="statementType" value="except" id={this.idFor("statement-type-except")} checked={statement.statementType == 'except'} onChange={this.onStatementTypeChange.bind(this, 'except')} />
              <label htmlFor={this.idFor("statement-type-except")}>All {resourcesLabel} except</label>
              {resourcesList['except']}
              <input type="radio" name="statementType" value="only" id={this.idFor("statement-type-only")} checked={statement.statementType == 'only'} onChange={this.onStatementTypeChange.bind(this, 'only')} />
              <label htmlFor={this.idFor("statement-type-only")}>Only some {resourcesLabel}</label>
              {resourcesList['only']}
            </div>
          </div>
        </div>
        <div className="row section">
          <div className="col px-1">
            <label className="section-name">Actions</label>
          </div>
          <div className="col">
            <div className="section-content">
              { Object.keys(actions).map(function(actionKey, index) {
                var action = actions[actionKey];
                return (
                  <div key={actionKey}>
                    <input type="checkbox" id={this.idFor("action-" + actionKey)} checked={this.statementHasAction(statement, action)} onChange={this.toggleAction.bind(this, action)} />
                    <label htmlFor={this.idFor("action-" + actionKey)}>{action.label}</label>
                  </div>
                );
              }.bind(this)) }
            </div>
          </div>
        </div>
      </div>;
    }
    return (
      <div>
        <div className="row section">
          <div className="col px-1">
            <label className="section-name">Delegable</label>
          </div>
          <div className="col">
            <div className="section-content">
              <input type="checkbox" id={this.idFor("delegable")} checked={statement.delegable} onChange={this.toggleDelegable} className="power" />
              <label htmlFor={this.idFor("delegable")}>Users CAN{statement.delegable ? "" : "NOT"} delegate permissions on this policy</label>
            </div>
          </div>
        </div>
        <div className="row section">
          <div className="col px-1">
            <label className="section-name">Type</label>
          </div>
          <div className="col">
            <div className="section-content">
              <CdxSelect items={this.props.resourceTypes} value={statement.resourceType} onChange={this.onResourceTypeChange} />
              <input type="checkbox" disabled="true" id={this.idFor("includeSubsites")} checked={statement.includeSubsites} onChange={this.toggleIncludeSubsites} />
              <label htmlFor={this.idFor("includeSubsites")}>Include subsites</label>
            </div>
          </div>
        </div>
        {ifResourceTypeSelected}
      </div>
    );
  },

});
