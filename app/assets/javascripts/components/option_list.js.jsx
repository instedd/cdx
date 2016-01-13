var OptionList = React.createClass({
  getInitialState: function() {
    return {
      chosenOnes: this.props.chosenOnes,
      showInput: false
    }
  },

  removeItem: function(item, event) {
    event.preventDefault();
    var index = this.state.chosenOnes.indexOf(item);
    var filtered = this.state.chosenOnes;
    filtered.splice(index, 1);
    this.setState(React.addons.update(this.state, {
      chosenOnes: { $set: filtered }
    }));
    $.ajax({
      url: '/users/' + this.props.userId + '/unassign_role',
      method: 'POST',
      data: {role: item.value},
      error: function () {
        this.appendItem(item);
      }.bind(this)
    });
  },

  appendItem: function(item) {
    this.setState(React.addons.update(this.state, {
      chosenOnes: { $push: [item] }
    }));
    $.ajax({
      url: '/users/' + this.props.userId + '/assign_role',
      method: 'POST',
      data: {role: item.value},
      error: function () {
        this.removeItem(item);
      }.bind(this)
    });
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
        { this.state.showInput ? null : <a className="btn-add-link" onClick={this.showInput} href="#"><span className="iconb-add"></span> Add role</a> }
        { this.state.showInput ? <AddItemSearch callback={"/roles/autocomplete"} onItemChosen={this.appendItem}
                placeholder="Search roles"
                itemTemplate={AddItemOptionList}
                itemKey="value" /> : null }
      </div>
    );
  }
});

var AddItemOptionList = React.createClass({
  render: function() {
    return (<span className="box-autocomplete" title={this.props.item.value}>{this.props.item.label}</span>);
  }
});
