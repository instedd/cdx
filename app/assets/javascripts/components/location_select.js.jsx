var LocationSelect = React.createClass({

  getInitialState: function() {
    return {
      value: { value: (this.props.value || this.props.defaultValue), label: (this.props.label || this.props.defaultLabel) },
      isLoading: !!(this.props.value || this.props.defaultValue),
      latlng: this.props.latlng
    }
  },

  componentDidMount: function() {
    var _this = this;
    if (this.props.defaultValue) {
      this.getDetails(this.props.defaultValue, function(location) {
        if (_this.isMounted()) {
          _this.setState(function(state) { return React.addons.update(state, {
            value: { $set: location },
            isLoading: { $set: false }
          })});
        }
      });
    }
  },

  getDefaultProps: function() {
    return {
      className: "input-large",
      placeholder: "Choose one",
      onChange: null,
      onError: null,
      clearable: false,
    };
  },

  componentWillReceiveProps: function(nextProps) {
    var _this = this;
    // Get latlng if specified and perform a reverse geo lookup on the location service,
    // and set the current value to the returned location, or clear value and call onError if none is found
    if (nextProps.latlng && nextProps.latlng.lat && nextProps.latlng.lng && !_.isEqual(nextProps.latlng, this.state.latlng)) {
      _this.setState(function(state) { return React.addons.update(state, { isLoading: { $set: true } }) });
      $.ajax(gon.location_service_url + "/lookup", {
        dataType: 'json',
        data: { x: nextProps.latlng.lng, y: nextProps.latlng.lat, limit: 1, ancestors: true },
        success: function(data) {
          if (_this.isMounted()) {
            var newState = { isLoading: { $set: false } };
            if (data.length == 0) {
              newState.value = { $set: null };
              newState.latlng = { $set: null };
              if (_this.props.onError) {
                _this.props.onError("A region could not be found for this address, please choose one;")
              }
            } else {
              newState.value = { $set: _this.formatLocation(data[0]) };
              newState.latlng = { $set: nextProps.latlng };
            }
            _this.setState(function(state) { return React.addons.update(state, newState); });
          }
        }
      })
    }
  },

  onChange: function(newValue, selection) {
    window.setTimeout(function(){
      // this is deferred so a new input with the new value
      // is rendered by the time the change event is triggered
      $('input:hidden', ReactDOM.getDOMNode(this)).trigger('change');
    }.bind(this), 0);

    var _this = this;
    var location = (selection && selection[0]) ? selection[0].location : null;
    var latlng = location ? { lat: location.lat, lng: location.lng} : null;
    _this.setState(function(state) { return React.addons.update(state, {
      value: { $set: _this.formatLocation(location) },
      latlng: { $set: latlng }
    })});

    if (_this.props.onChange) {
      _this.props.onChange(newValue, location);
    }
  },

  render: function() {
    var _this = this;

    return <div>
      <label style={{ display: "none" }}>disableautocomplete</label>
      <Select className={this.props.className}
        name={this.props.name}
        value={this.state.value}
        placeholder={this.props.placeholder}
        clearable={this.props.clearable}
        asyncOptions={this.getOptions}
        isLoading={this.state.isLoading}
        autoload={false}
        onChange={this.onChange}>
      </Select>
    </div>;
  },

  // private

  getDetails: function(id, callback) {
    var _this = this;
    $.ajax(gon.location_service_url + "/details", {
      dataType: 'json',
      data: { id: id, ancestors: true },
      success: function(data) {
        if (data.length > 0) {
          callback(_this.formatLocation(data[0]));
        } else {
          callback(null);
        }
      }
    });
  },

  getOptions: function(input, callback) {
    // getOptions is sometimes called with an object with name/value rather than the actual string
    if (typeof(input) != "string" || _.isEmpty(input)) {
      callback(null, {options: []});
      return;
    }
    var _this = this;
    $.get(gon.location_service_url + "/suggest", { name: input, limit: 100, ancestors: true, set: gon.location_service_set }, function(data) {
      callback(null, { options: _.map(data, _this.formatLocation), complete: data.length < 100 });
    }, 'json').fail(function(err) { callback(err) });
  },

  formatLocation: function(location) {
    if (location == null) {
      return {value: null, label: '', location: null};
    }
    var name = location.name;
    if (location.ancestors && location.ancestors.length > 0) {
      var ancestorsNames = _.pluck(location.ancestors, 'name');
      name += (" (" + ancestorsNames.reverse().join(", ") + ")");
    }
    return {
      value: location.id,
      label: name,
      location: location
    }
  }

});
