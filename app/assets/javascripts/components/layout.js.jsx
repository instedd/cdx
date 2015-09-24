var FlexFullRow = React.createClass({
  render: function() {
    return (
      <div className="row">
        <div className="col">
          {this.props.children}
        </div>
      </div>
    );
  }
});
