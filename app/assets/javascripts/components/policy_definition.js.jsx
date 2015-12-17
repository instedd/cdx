var PolicyDefinition = React.createClass({
  getInitialState: function() {
    return {
      statements: (this.props.definition || {}).statement || [],
      activeTab: 0
    };
  },

  newPolicy: function() {
    this.setState(React.addons.update(this.state, {
      statements: { $push: [{ delegable: false, resourceType: null, includeSubsites: false}] }
    }));
  },

  toggleDelegable: function(index) {
    console.log("FIXME - index always get bound to 0");
    this.setState(React.addons.update(this.state, {
      statements: {
        [index]: {
          delegable: { $apply: function(current) { return !current; } }
        }
      }
    }));
  },

  onResourceTypeChange: function(index, newValue) {
    this.setState(React.addons.update(this.state, {
      statements: {
        [index]: {
          resourceType: { $set: newValue }
        }
      }
    }));
  },

  toggleIncludeSubsites: function(index) {
    this.setState(React.addons.update(this.state, {
      statements: {
        [index]: {
          includeSubsites: { $apply: function(current) { return !current; } }
        }
      }
    }));
  },

  setActiveTab: function(index) {
    this.setState(React.addons.update(this.state, {
      activeTab: { $set: index }
    }));
  },

  render: function() {
    return (
      <div>
        <div className="left-column">
          <div className="tabs">
            <ul className="tabs-header">
              {this.state.statements.map(function(statement, index){
                return <li key={index} onClick={this.setActiveTab.bind(this,index)}><PolicyItem statement={statement} /></li>;
              }.bind(this))}
              <li><a onClick={this.newPolicy} href="javascript:">Add policy</a></li>
            </ul>
            {this.state.statements.map(function(statement, index) {
              var tabClass = "tabs-content" + (this.state.activeTab === index ? " selected" : "");
              return (<div className={tabClass} key={index}><PolicyItemDetail statement={statement} toggleDelegable={this.toggleDelegable.bind(this, index)} onResourceTypeChange={this.onResourceTypeChange.bind(this, index)} toggleIncludeSubsites={this.toggleIncludeSubsites.bind(this, index)} /></div>);
            }.bind(this))}
          </div>
        </div>

      </div>
    )
  }
});
