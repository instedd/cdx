var PolicyItemDetail = React.createClass({
  resourceTypes: [
    {value: 'site', label: 'Site'},
    {value: 'device', label: 'Device'},
    {value: 'testResult', label: 'Test Result'},
    {value: 'encounter', label: 'Encounter'}
  ],

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

  onResourcesChange: function(selected) {
    this.props.updateStatement({resources: { $set: selected}});
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

  render: function() {
    var statement = this.props.statement;
    var resourcesList = {
      "except": <div className="without-resources-except-list" />,
      "only": <div className="without-resources-only-list" />
    }
    var ifResourceTypeSelected = <div className="without-resource-type" />;
    if(statement.resourceType != null) {
      if(statement.resources != null && statement.resources != "all") {
        // FIXME: actually list resources
        resourcesList[statement.resources] = (<div className="resources-list">
          Aca va la lista
        </div>);
      }

      var actions = this.props.actions[statement.resourceType];

      ifResourceTypeSelected = <div className="with-resource-type">
        <div className="section">
          <span className="section-name">Resources</span>
          <div className="section-content">
            <input type="radio" name="resources" value="all" id={this.idFor("resources-all")} checked={statement.resources == 'all'} onChange={this.onResourcesChange.bind(this, 'all')} />
            <label htmlFor={this.idFor("resources-all")}>All resources</label>
            <input type="radio" name="resources" value="except" id={this.idFor("resources-except")} checked={statement.resources == 'except'} onChange={this.onResourcesChange.bind(this, 'except')} />
            <label htmlFor={this.idFor("resources-except")}>All resources except</label>
            {resourcesList['except']}
            <input type="radio" name="resources" value="only" id={this.idFor("resources-only")} checked={statement.resources == 'only'} onChange={this.onResourcesChange.bind(this, 'only')} />
            <label htmlFor={this.idFor("resources-only")}>Only some</label>
            {resourcesList['only']}
          </div>
        </div>
        <div className="section">
          <span className="section-name">Actions</span>
          <div className="section-content">
            <input type="checkbox" id={this.idFor("action-inherit")} checked={statement.actions.inherit} onChange={this.toggleAction.bind(this, 'inherit')} />
            <label htmlFor={this.idFor("action-inherit")}>Inherit permissions from granter</label>
            { /** FIXME: disable actions if Inherit is selected */ }
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
      </div>;
    }
    return (
      <div>
        <div className="section">
          <span className="section-name">Delegable</span>
          <div className="section-content">
            <input type="checkbox" id={this.idFor("delegable")} checked={statement.delegable} onChange={this.toggleDelegable} />
            <label htmlFor={this.idFor("delegable")}>Users CAN{statement.delegable ? "" : "NOT"} delegate permissions on this policy</label>
          </div>
        </div>
        <div className="section">
          <span className="section-name">Type</span>
          <div className="section-content">
            <CdxSelect items={this.resourceTypes} value={statement.resourceType} onChange={this.onResourceTypeChange} />
            <input type="checkbox" id={this.idFor("includeSubsites")} checked={statement.includeSubsites} onChange={this.toggleIncludeSubsites} />
            <label htmlFor={this.idFor("includeSubsites")}>Include subsites</label>
          </div>
        </div>
        {ifResourceTypeSelected}
      </div>
    );
  },

});
