var LocationSelect = React.createClass({

  getInitialState: function() {
    return {
      value: { value: this.props.defaultValue, label: (this.props.defaultLabel || this.props.defaultValue) },
      isLoading: !!this.props.defaultValue
    }
  },

  componentDidMount: function() {
    var _this = this;
    if (this.props.defaultValue) {
      this.getDetails(this.props.defaultValue, function(location) {
        if (_this.isMounted()) {
          _this.setState(React.addons.update(_this.state, {
            value: { $set: location },
            isLoading: { $set: false }
          }));
        }
      });
    }
  },

  getDefaultProps: function() {
    return {
      className: "input-large",
      placeholder: "Choose one",
      onChange: null,
      onError: null
    };
  },

  componentWillReceiveProps: function(nextProps) {
    var _this = this;
    // Get revLatLng if specified and perform a reverse geo lookup on the location service,
    // and set the current value to the returned location, or clear value and call onError if none is found
    if (nextProps.revLatLng && nextProps.revLatLng != this.props.revLatLng) {
      _this.setState(React.addons.update(_this.state, { isLoading: { $set: true } }));
      $.ajax(gon.location_service_url + "/lookup", {
        dataType: 'json',
        data: { x: nextProps.revLatLng.lng, y: nextProps.revLatLng.lat, limit: 1, ancestors: true },
        success: function(data) {
          if (_this.isMounted()) {
            var newState = { isLoading: { $set: false } };
            if (data.length == 0) {
              newState.value = { $set: null };
              if (_this.props.onError) {
                _this.props.onError("A city could not be found for this address, please choose one;")
              }
            } else {
              newState.value = { $set: _this.formatLocation(data[0]) };
            }
            _this.setState(React.addons.update(_this.state, newState));
          }
        }
      })
    }
  },

  onChange: function(newValue) {
    window.setTimeout(function(){
      // this is deferred so a new input with the new value
      // is rendered by the time the change event is triggered
      $('input:hidden', this.getDOMNode()).trigger('change');
    }.bind(this), 0);

    if (this.props.onChange) {
      this.props.onChange(newValue);
    }
  },

  render: function() {
    var _this = this;

    return (<Select className={this.props.className}
      name={this.props.name}
      value={this.state.value}
      placeholder={this.props.placeholder}
      clearable={false}
      asyncOptions={this.getOptions}
      isLoading={this.state.isLoading}
      autoload={false}
      onChange={this.onChange}>
    </Select>);
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
    var _this = this;
    $.get(gon.location_service_url + "/suggest", { name: input, limit: 100, ancestors: true, set: gon.location_service_set }, function(data) {
      callback(null, { options: _.map(data, _this.formatLocation), complete: data.length < 100 });
    }, 'json').fail(function(err) { callback(err) });
  },

  formatLocation: function(location) {
    var name = location.name;
    if (location.ancestors && location.ancestors.length > 0) {
      var ancestorsNames = _.pluck(location.ancestors, 'name');
      name += (" (" + ancestorsNames.reverse().join(", ") + ")");
    }
    return {
      value: location.id,
      label: name
    }
  }

});
