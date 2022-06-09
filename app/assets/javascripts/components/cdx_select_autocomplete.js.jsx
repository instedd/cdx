var CdxSelectAutocomplete = React.createClass({
  getInitialState: function () {
    return {
      options: null,
    };
  },

  render: function () {
    return (<Select
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
    if (!query || /^\s*$/.test(query)) {
      return callback(null, []);
    }

    var url = this.props.url;
    url += (url.includes("?") ? "&query=" : "?query=") + encodeURIComponent(query.trim());

    $.ajax({
      type: this.props.method || "GET",
      url: url,

      success: function (options) {
        callback(null, {
          options: options,
          complete: options.size < 10,
        });
      },

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
});
