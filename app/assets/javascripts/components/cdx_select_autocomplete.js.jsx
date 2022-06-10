var CdxSelectAutocomplete = React.createClass({
  getInitialState: function () {
    return {
      options: null,
    };
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
