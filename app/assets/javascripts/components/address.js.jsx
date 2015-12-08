var Address = React.createClass({

  getInitialState: function() {
    return {
      address: this.props.defaultAddress,
      location: this.props.defaultLocation,
      latlng: this.props.defaultLatLng
    }
  },

  getDefaultProps: function() {
    return {
      addressName: "address",
      locatioName: "location",
      latName: "lat",
      lngName: "lng"
    };
  },

  handleAddress: function(newAddress) {
    var _this = this;
    _this.setState(React.addons.update(_this.state, {
      bounds: { $set: newAddress.bbox },
      address: { $set: newAddress.name },
      latlng: { $set: newAddress.center }
    }));
  },

  render: function() {
    var latlng, position, zoom, marker, bound, _this = this;
    bounds = this.state.bounds;
    latlng = this.state.latlng ? [this.state.latlng.lat, this.state.latlng.lng] : null;
    position = bounds ? null : (latlng || gon.location_default);
    zoom = bounds ? null : (latlng ? (this.state.zoom || 12) : 2);

    if (latlng) {
      var onMarkerDragEnd = function (event) {
        _this.setState(React.addons.update(_this.state, {
          bounds: { $set: null },
          latlng: { $set: event.target.getLatLng() },
          zoom: { $set: _this.refs.map.getLeafletElement().getZoom() }
        }));
      };
      marker = <ReactLeaflet.Marker position={latlng} draggable={true} onLeafletDragend={onMarkerDragEnd} />;
    }

    return <div>
      <div className="row">
        <div className="col pe-2">
          <label>Address</label>
        </div>
        <div className="col pe-5">
          <AddressAutosuggest name={this.props.addressName} value={this.state.address} onAddress={this.handleAddress} className="input-xx-large" />
        </div>
        <div className="col pe-5">
          <LocationSelect placeholder="Choose a location" name={this.props.locationName} defaultValue={this.state.location} className="input-x-large" />
        </div>
      </div>
      <div className="row">
        <div className="col pe-2"></div>
        <div className="col pe-8">
          <input type="hidden" value={latlng ? latlng[0] : null} name={this.props.latName}></input>
          <input type="hidden" value={latlng ? latlng[1] : null} name={this.props.lngName}></input>
          <ReactLeaflet.Map ref="map" center={position} zoom={zoom} bounds={bounds} className="map">
            <ReactLeaflet.TileLayer
              url='http://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png'
              attribution='&copy; <a href="http://openstreetmap.org">OpenStreetMap</a> contributors, <a href="http://creativecommons.org/licenses/by-sa/2.0/">CC-BY-SA</a>'
            />
            { marker }
          </ReactLeaflet.Map>
        </div>
      </div>
    </div>
  }

});
