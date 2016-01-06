var AddItemSearch = React.createClass({
  getDefaultProps: function() {
    return {
      placeholder: "Search"
    }
  },

  getInitialState: function(){
    return { items: [] }
  },

  chooseItem: function(item) {
    this.props.onItemChosen(item);
    this.setState(React.addons.update(this.state, {
      items: { $set: [] }
    }));
  },

  // debounce: http://stackoverflow.com/a/24679479/30948
  componentWillMount: function() {
    this.handleSearchDebounced = _.debounce(function(){
      this.handleSearch.apply(this, [this.state.query]);
    }, 500);
  },

  onChange: function(event) {
    this.setState(React.addons.update(this.state, {
      query: { $set: event.target.value }
    }));
    this.handleSearchDebounced();
  },

  handleSearch: function(query) {
    if(query == '') {
      console.log('hi!');
      this.setState(React.addons.update(this.state, {
        items: { $set: [] }
      }));
    } else {
      $.ajax({
        url: this.props.callback,
        data: { q: query },
        success: function(data) {
          this.setState(React.addons.update(this.state, {
            items: { $set: data }
          }));
        }.bind(this)
      });
    }
  },

  render: function() {
    templateFactory = React.createFactory(this.props.itemTemplate)
    itemKey = this.props.itemKey

    return (
      <div className="item-search">
        <input type="text" ref="input" placeholder={this.props.placeholder} className="input-block" onChange={this.onChange} onFocus={this.onChange} autoFocus="true"></input>
        <ul>
          {this.state.items.map(function(item) {
            return <li key={item[itemKey]} onClick={this.chooseItem.bind(this, item)}>{templateFactory({item: item})}</li>;
          }.bind(this))}
        </ul>
      </div>
    );
  }

});
