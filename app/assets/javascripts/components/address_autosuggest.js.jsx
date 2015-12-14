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
      className: this.props.className
    };

    return <Autosuggest
      value={this.props.value}
      suggestions={this.geolocate}
      suggestionRenderer={this.renderSuggestion}
      suggestionValue={this.getSuggestionValue}
      inputAttributes={inputAttributes}
      onSuggestionSelected={this.props.onAddress}
    />
  },

  // private

  geolocate: _.debounce(function(value, callback) {
    var _this = this;
    this.geocoder.geocode(value, function(locations) {
      callback(null, locations);
      if (locations.length == 0 && _this.props.onError) {
        _this.props.onError("The address could not be found, please choose a city and a location in the map");
      }
    }, this);
  }, 300),

  renderSuggestion: function(suggestion, input) {
    return suggestion.name;
  },

  getSuggestionValue: function(suggestion) {
    return suggestion.name;
  }

});
