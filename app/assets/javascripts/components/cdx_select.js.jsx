var CdxSelect = React.createClass({
  getDefaultProps: function() {
    return {
      className: "input-large"
    };
  },

  onChange: function(newValue) {
    window.setTimeout(function(){
      // this is deferred so a new input with the new value
      // is rendered by the time the change event is triggered
      $('input:hidden', this.getDOMNode()).trigger('change');
    }.bind(this), 0);
    if(this.props.onChange) {
      this.props.onChange(newValue, this);
    }
  },

  // Searchable selects don't prevent typing whatever, in which case the input
  // will have the invalid value, yet the value sent by the form will be empty
  // or worse: a valid value that was previously selected, leading to send a
  // value that doesn't reflect what's on the screen, and the backend to
  // validate a value when it should fail.
  //
  // To counter this problem, we copy the typed value, so what we send to the
  // backend reflects what's visible in the UI.
  onInputChange: function (newValue) {
    this.selectRef.setValue(newValue)
  },

  render: function() {
    var placeholder = "Choose one"
    if (this.props.items.length > 0 && this.props.items[0].value === "") {
      placeholder = this.props.items[0].label;
    }

    return (<Select className={this.props.className}
      ref={(ref) => { this.selectRef = ref }}
      name={this.props.name}
      value={this.props.value}
      options={this.props.items}
      placeholder={placeholder}
      clearable={false}
      multi={this.props.multi}
      searchable={this.props.searchable}
      onChange={this.onChange}
      onInputChange={this.props.searchable && this.onInputChange}>
    </Select>);
  }
});
