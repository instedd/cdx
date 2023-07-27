var CdxSelectAutocomplete = React.createClass({
  getDefaultProps: function() {
    return {
      className: "input-large"
    };
  },

  getInitialState: function () {
    return {
      options: null,
    };
  },

  componentWillMount: function () {
    this.asyncOptions = _.debounce(this.asyncOptions.bind(this), 100, { maxWait: 250 });
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
      onBlur= {this.onBlur}
    />);
  },

  asyncOptions: function (query, callback) {
    query = query.trim();
    if (!query) return callback(null, []);

    var autoselect = this.props.autoselect;
    var prepareOptions = this.props.prepareOptions;
    var url = this.props.url;
    url += (url.includes("?") ? "&query=" : "?query=") + encodeURIComponent(query);

    this.cancelAjax();
    
    this.xhr = $.ajax({
      type: this.props.method || "GET",
      url: url,

      success: function (options) {
        if (!this.selectRef.state.isFocused) {
          this.selectRef.setState({ isLoading: false });
          return;
        }
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
        if (error !== "abort") {
          callback(error);
        }
      },
    })
  },

  onBlur: function () {
    this.selectRef.setState({ isLoading: false });
    this.cancelAjax()
  },

  onChange: function (value, options) {
    if (this.props.onSelect) {
      this.props.onSelect.call(null, value, options);
    }
  },

  setSelectRef: function (ref) {
    this.selectRef = ref;
  },

  cancelAjax: function () {
    if (this.xhr) this.xhr.abort();
  }
});
