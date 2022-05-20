var CdxSelectAutocomplete = React.createClass({
  render: function () {
    return (<Select
      className={this.props.className}
      name={this.props.name}
      value={this.props.value}
      placeholder={this.props.placeholder}
      searchable={true}
      clearable={true}
      asyncOptions={this.asyncOptions.bind(this)}
    />);
  },

  asyncOptions: function (query, callback) {
    if (!query || /^\s*$/.test(query)) {
      return callback(null, []);
    }

    var url = this.props.url;
    url += (url.includes("?") ? "&query=" : "?query=") + encodeURIComponent(query);

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
});
