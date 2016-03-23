var AddressAutosuggest = React.createClass({

  propTypes: {
    name:         React.PropTypes.string,
    geocoder:     React.PropTypes.string,
    geocoderOpts: React.PropTypes.object,
    className:    React.PropTypes.string,
    onChange:     React.PropTypes.func,
    onAddress:    React.PropTypes.func,
    onError:      React.PropTypes.func
  },

  componentDidMount: function() {
    this.geocoder = new L.Control.Geocoder[this.props.geocoder](this.props.geocoderOpts);
  },

  getDefaultProps: function() {
    return {
      name: "address",
      geocoder: gon.location_geocoder,
      geocoderOpts: {},
      className: 'input-x-large'
    }
  },

  render: function() {
    var inputAttributes = {
      name: this.props.name,
      onChange: this.props.onChange,
      className: this.props.className,
      autoComplete: "off"
    };

    return <div>
      <label style={{ display: "none" }}>disableautocomplete</label>
      <input type="text" name={this.props.name} onBlur={this.handleBlur} onChange={this.handleChange} className={this.props.className} autoComplete="off" value={this.props.value} />
    </div>
  },

  // private

  handleChange: function(evt) {
    if (this.props.onChange) {
      this.props.onChange(evt.target.value);
    }
  },

  handleBlur: function() {
    var _this = this;
    this.geocoder.geocode(_this.props.value, function(locations) {
      if (locations.length == 0 && _this.props.onError) {
        _this.props.onError("The address could not be found, please choose a city and a location in the map");
      } else if (locations.length > 0) {
        _this.props.onAddress(locations[0]);
      }
    }, this);
  }

});
