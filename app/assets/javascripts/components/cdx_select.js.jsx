var CdxSelect = React.createClass({
  render: function() {
    return (<Select className="input-large"
      name={this.props.name}
      value={this.props.value}
      options={this.props.items}
      clearable={false}>
    </Select>);
  }
});
