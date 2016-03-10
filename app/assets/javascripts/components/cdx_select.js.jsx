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

  render: function() {
    var placeholder = "Choose one"
    if (this.props.items.length > 0 && this.props.items[0].value === "") {
      placeholder = this.props.items[0].label;
    }

    return (<Select className={this.props.className}
      name={this.props.name}
      value={this.props.value}
      options={this.props.items}
      placeholder={placeholder}
      clearable={false}
      multi={this.props.multi}
      onChange={this.onChange}>
    </Select>);
  }
});
