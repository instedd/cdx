var Address = React.createClass({

  getInitialState: function() {
    return {
      address: this.props.defaultAddress,
      addressSet: !!this.props.defaultAddress,
      latlng: this.props.defaultLatLng,
      error: null
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
    _this.setState(function(state) {
      return React.addons.update(state, {
        bounds: { $set: newAddress.bbox },
        addressSet: { $set: true },
        latlng: { $set: { lat: newAddress.center.lat, lng: newAddress.center.lng } },
        error: { $set: null }
      })});
  },

  handleAddressChange: function(newAddress) {
    this.setState(function(state) { return React.addons.update(state, {
      address: { $set: newAddress },
      addressSet: { $set: (_.isEmpty(newAddress) ? false : state.addressSet) }
    }) });
  },

  handleLocationChange: function(value, newLocation) {
    // Update lat lng upon a location change only if address is empty or did not resolve to a location
    if (!this.hasValidAddress(this.state)) {
      this.setState(React.addons.update(this.state, {
        latlng: { $set: { lat: newLocation.lat, lng: newLocation.lng} }
      }));
    }
  },

  handleError: function(err) {
    var _this = this;
    _this.setState(React.addons.update(_this.state, {
      error: { $set: err }
    }));
  },

  hasValidAddress: function(state) {
    return !_.isEmpty(_.trim(state.address));
  },

  render: function() {
    var latlng, revLatLng, position, zoom, marker, bounds, onMapClick, _this = this;
    bounds = this.state.bounds;
    latlng = (this.state.latlng && this.state.latlng.lat && this.state.latlng.lng) ? [this.state.latlng.lat, this.state.latlng.lng] : null;
    revLatLng = this.state.addressSet ? this.state.latlng : null;
    position = bounds ? null : (latlng || gon.location_default);
    zoom = bounds ? null : (latlng ? (this.state.zoom || 12) : 2);

    if (latlng) {
      var onMarkerDragEnd = function(event) {
        _this.setState(React.addons.update(_this.state, {
          bounds: { $set: null },
          latlng: { $set: event.target.getLatLng() },
          zoom: { $set: _this.refs.map.getLeafletElement().getZoom() }
        }));
      };
      onMapClick = _.noop;
      marker = <ReactLeaflet.Marker position={latlng} draggable={true} onLeafletDragend={onMarkerDragEnd} />;
    } else {
      onMapClick = function(event) {
        _this.setState(React.addons.update(_this.state, {
          bounds: { $set: null },
          latlng: { $set: event.latlng },
          zoom: { $set: _this.refs.map.getLeafletElement().getZoom() }
        }));
      };
    }

    return <div>
      <div className="row">
        <div className="col pe-2">
          <label>Address</label>
        </div>
        <div className="col pe-8">
          <AddressAutosuggest name={this.props.addressName} value={this.state.address} onChange={this.handleAddressChange} onAddress={this.handleAddress} onError={this.handleError} className="input-block" />
          <div className="warn">{this.state.error}</div>
        </div>
      </div>
      <div className="row">
        <div className="col pe-2">
          <label>Region</label>
        </div>
        <div className="col">
          <LocationSelect placeholder="Choose a location" name={this.props.locationName} defaultValue={this.props.defaultLocation} latlng={revLatLng} onChange={this.handleLocationChange} onError={this.handleError} className="input-x-large" />
        </div>
      </div>
      <div className="row">
        <div className="col pe-2"></div>
        <div className="col pe-8">
          <input type="hidden" value={latlng ? latlng[0] : null} name={this.props.latName}></input>
          <input type="hidden" value={latlng ? latlng[1] : null} name={this.props.lngName}></input>
          <ReactLeaflet.Map ref="map" center={position} zoom={zoom} bounds={bounds} className="map" onLeafletClick={onMapClick}>
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
