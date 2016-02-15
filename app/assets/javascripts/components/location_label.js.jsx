var LocationLabel = React.createClass({

  getInitialState: function() {
    return {label: ""};
  },

  componentDidMount: function() {
    $.ajax(gon.location_service_url + "/details", {
      dataType: 'json',
      data: { id: this.props.id, ancestors: true },
      success: function(data) {
        if (data.length > 0) {
          this.setState(function(state) { return React.addons.update(state, {
            label: { $set: data[0].name }
          })});
        }
      }.bind(this)
    });
  },

  render: function() {
    return <div>
      {this.state.label}
    </div>
  }

});
