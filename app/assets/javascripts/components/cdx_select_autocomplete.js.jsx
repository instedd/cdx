var CdxSelectAutocomplete = React.createClass({
  getInitialState: function () {
    return {
      options: null,
    };
  },

  // Since <Select> uses a different INPUT we must copy the value when the
  // user is typing from the visible to the hidden INPUT, otherwise when the
  // user enters free-text of validates with an invalid value, the backend won't
  // know about the value and silently skip it.
  copyValue: function (newValue) {
    // we can't use setValue() because it has too many side effects, we only
    // want to set the hidden input's value:
    this.selectRef.setState({ value: newValue });
  },

  render: function () {
    return (<Select
      ref={this.setSelectRef}
      className={this.props.className}
      name={this.props.name}
      value={this.props.value}
      placeholder={this.props.placeholder}
      searchable={true}
      clearable={true}
      asyncOptions={this.asyncOptions}
      value={this.props.value || ""}
      onChange={this.onChange}
      onInputChange={this.props.combobox && this.copyValue}
    />);
  },

  asyncOptions: function (query, callback) {
    query = query.trim();
    if (!query) return callback(null, []);

    var autoselect = this.props.autoselect;
    var prepareOptions = this.props.prepareOptions;
    var url = this.props.url;
    url += (url.includes("?") ? "&query=" : "?query=") + encodeURIComponent(query);

    $.ajax({
      type: this.props.method || "GET",
      url: url,

      success: function (options) {
        if (prepareOptions) {
          options = prepareOptions.call(null, options);
        }
        callback(null, {
          options: options,
          complete: options.size < 10,
        });
        if (autoselect && options.length === 1 && options[0].value === query) {
          this.selectRef.setValue(query);
        }
      }.bind(this),

      error: function (_, error) {
        callback(error);
      },
    })
  },

  onChange: function (value, options) {
    if (this.props.onSelect) {
      this.props.onSelect.call(null, value, options);
    }
  },

  setSelectRef: function (ref) {
    this.selectRef = ref;
  }
});
