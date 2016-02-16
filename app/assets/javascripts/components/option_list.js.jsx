var OptionList = React.createClass({
  getInitialState: function() {
    return {
      chosenOnes: this.props.chosenOnes ? this.props.chosenOnes : [],
      showInput: this.props.showInput ? this.props.showInput : false,
      placeholder: this.props.placeholder ? this.props.placeholder : "Search"
    }
  },

  removeItem: function(item, event) {
    event.preventDefault();
    var old = _.clone(this.state.chosenOnes);
    var index = this.state.chosenOnes.indexOf(item);
    var filtered = this.state.chosenOnes;
    filtered.splice(index, 1);
    this.setState(React.addons.update(this.state, {
      chosenOnes: { $set: filtered }
    }));
    if(typeof(this.props.callback) == "string") {
      $.ajax({
        url: this.props.callback,
        method: 'POST',
        data: {remove: item.value},
        error: function () {
          this.setState(React.addons.update(this.state, {
            chosenOnes: { $set: old }
          }));
        }.bind(this)
      });
    } else {
      this.props.callback(filtered);
    }
  },

  appendItem: function(item) {
    var old = _.clone(this.state.chosenOnes);
    this.setState(React.addons.update(this.state, {
      chosenOnes: { $push: [item] }
    }), function() {
      if(typeof(this.props.callback) == "function") {
        this.props.callback(this.state.chosenOnes);
      }
    });
    if(typeof(this.props.callback) == "string") {
      $.ajax({
        url: this.props.callback,
        method: 'POST',
        data: {add: item.value},
        error: function () {
          this.setState(React.addons.update(this.state, {
            chosenOnes: { $set: old }
          }));
        }.bind(this)
      });
    }
  },

  appendNonExistantItem: function(text) {
    if(this.props.allowNonExistent) {
      var nonExistantItem = {value: text, label: text};
      this.appendItem(nonExistantItem);
    }
  },

  showInput: function(event) {
    event.preventDefault();
    this.setState(React.addons.update(this.state, {
      showInput: { $set: true }
    }));
  },

  render: function() {
    return (
      <div className="option-list">
        <ul className="box-list">
          {this.state.chosenOnes.map(function(item) {
            return (<li key={item.value}>
              <span>{item.label}</span>
              <a className="remove" href="#" onClick={this.removeItem.bind(this, item)}><img src="/assets/ic-cross.png"/></a>
            </li>);
          }.bind(this))}
        </ul>
        { this.state.showInput ? null : <a className="btn-add-link" onClick={this.showInput} href="#"><span className="icon-circle-plus icon-blue"></span>Add</a> }
        { this.state.showInput ? <AddItemSearch callback={this.props.autocompleteCallback} onItemChosen={this.appendItem} context={this.props.context}
                itemTemplate={AddItemOptionList}
                itemKey="value"
                onNonExistentItem={this.appendNonExistantItem}
                placeholder={this.state.placeholder} /> : null }
      </div>
    );
  }
});

var AddItemOptionList = React.createClass({
  render: function() {
    return (<span className="box-autocomplete" title={this.props.item.value}>{this.props.item.label}</span>);
  }
});
