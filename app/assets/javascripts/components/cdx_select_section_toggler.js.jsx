var CdxSelectSectionToggler = React.createClass({
  componentDidMount() {
    this.toggle(this.props.value)
  },

  render: function () {
    return (<CdxSelect
      items={this.props.items}
      value={this.props.value}
      onChange={this.toggle.bind(this)}
      searchable={false}
    />);
  },

  toggle: function (value) {
    // enable form
    this.props.items.forEach(function (item) {
      this.toggleSection(item.value, "none", true)
    }.bind(this));

    // enable selected section
    this.toggleSection(value, "block", false)

    // enable form
    if (this.props.submit) {
      var submit = document.querySelector(this.props.submit)
      submit.disabled = !value
    }
  },

  toggleSection: function (id, display, disabled)  {
    if (!id) return

    var section = document.querySelector("#" + id);

    Array.from(section.querySelectorAll("input, select, textarea"))
      .forEach(function (element) { element.disabled = disabled; });

    section.style.display = display;
  }
})
