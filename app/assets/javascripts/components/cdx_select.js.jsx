var CdxSelect = React.createClass({
  getDefaultProps: function() {
    return {
      className: "input-large"
    };
  },

  render: function() {
    return (<Select className={this.props.className}
      name={this.props.name}
      value={this.props.value}
      options={this.props.items}
      clearable={false}>
    </Select>);
  }
});
