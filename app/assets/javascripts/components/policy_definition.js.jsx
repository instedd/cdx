var Tab = ReactTabs.Tab;
var Tabs = ReactTabs.Tabs;
var TabList = ReactTabs.TabList;
var TabPanel = ReactTabs.TabPanel;

var PolicyDefinition = React.createClass({
  getInitialState: function() {
    return {
      statements: (this.props.definition || {}).statement || []
    };
  },

  newPolicy: function() {
    this.setState(React.addons.update(this.state, {
      statements: { $push: [{ delegable: false}] }
    }));
  },

  toggleDelegable: function(index) {
    this.setState(React.addons.update(this.state, {
      statements: {
        [index]: {
          delegable: { $apply: function(current) { return !current; } }
        }
      }
    }));
  },

  render: function() {
    return (
      <div>
        <div className="left-column">
          <Tabs>
            <TabList>
              {this.state.statements.map(function(statement, index){
                return <Tab><PolicyItem statement={statement} /></Tab>;
              })}
              <Tab><a onClick={this.newPolicy} href="javascript:">Add policy</a></Tab>
            </TabList>
            {this.state.statements.map(function(statement, index){
              return <TabPanel><PolicyItemDetail statement={statement} toggleDelegable={this.toggleDelegable.bind(this, index)} /></TabPanel>;
            }.bind(this))}
            <TabPanel>Add policy panel</TabPanel>
          </Tabs>
        </div>

      </div>
    )
  }
});
