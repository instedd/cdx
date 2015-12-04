var AddressAutosuggest = React.createClass({

  propTypes: {
    name:         React.PropTypes.string,
    geocoder:     React.PropTypes.string,
    geocoderOpts: React.PropTypes.object,
    className:    React.PropTypes.string,
    onChange:     React.PropTypes.func.isRequired
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
      className: this.props.className
    };

    return <Autosuggest value={this.props.value} suggestions={this.geolocate} inputAttributes={inputAttributes} />
  },

  geolocate: _.debounce(function(value, callback) {
    var _this = this;
    this.geocoder.geocode(value, function(locations) {
      callback(null, _.pluck(locations, 'name'));
    }, this);
  }, 300)

});
