var CdxSelect = React.createClass({
  getDefaultProps: function() {
    return {
      className: "input-large"
    };
  },

  render: function() {
    var placeholder = "Select..."
    if (this.props.items.length > 0 && this.props.items[0].value === "") {
      placeholder = this.props.items[0].label;
    }

    return (<Select className={this.props.className}
      name={this.props.name}
      value={this.props.value}
      options={this.props.items}
      placeholder={placeholder}
      clearable={false}>
    </Select>);
  }
});
