var Address = React.createClass({

  getInitialState: function() {
    return {
      address: this.props.defaultAddress,
      location: this.props.defaultLocation
    }
  },

  getDefaultProps: function() {
    return {
      addressName: "address",
      locatioName: "location"
    };
  },

  handleAddress: function(newAddress) {

  },

  render: function() {
    return <div>
      <div className="row">
        <div className="col pe-2">
          <label>Address</label>
        </div>
        <div className="col pe-5">
          <AddressAutosuggest name={this.props.addressName} value={this.state.address} onChange={this.handleAddress} className="input-xx-large" />
        </div>
        <div className="col pe-5">
          <LocationSelect placeholder="Choose a location" name={this.props.locationName} defaultValue={this.state.location} className="input-x-large" />
        </div>
      </div>
      <div className="row">
        <div className="col pe-2"></div>
        <div className="col pe-8">
          <Map></Map>
        </div>
      </div>
    </div>
  }
});
