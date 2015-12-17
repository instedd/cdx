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
              return (<div className={tabClass} key={index}><PolicyItemDetail statement={statement} index={index} updateStatement={this.updateStatement.bind(this, index)} /></div>);
            }.bind(this))}
          </div>
        </div>

      </div>
    )
  }
});
