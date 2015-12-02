var LocationSelect = React.createClass({

  getDefaultProps: function() {
    return {
      className: "input-large"
    };
  },

  onChange: function(newValue) {
    window.setTimeout(function(){
      // this is deferred so a new input with the new value
      // is rendered by the time the change event is triggered
      $('input:hidden', this.getDOMNode()).trigger('change');
    }.bind(this), 0);
  },

  render: function() {
    var _this = this;
    var placeholder = "Choose one";

    // If the initial value is just an id, issue an initial ajax request to get the label
    // and modify props.value accordingly
    var value = null;
    var isLoading = null;
    if (this.props.value && this.props.value.value) {
      value = this.props.value;
      isLoading = false;
    } else {
      isLoading = true;
      value = { value: this.props.value, label: this.props.value };
      this.getDetails(this.props.value, function(location) {
        _this.setProps(React.addons.update(_this.props, {
          value: { $set: location },
        }));
      });
    }

    return (<Select className={this.props.className}
      name={this.props.name}
      value={value}
      placeholder={placeholder}
      clearable={false}
      asyncOptions={this.getOptions}
      isLoading={isLoading}
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
        }
      }
    });
  },

  getOptions: function(input, callback) {
    console.log("Invoking with " + JSON.stringify(input));
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
