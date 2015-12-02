var SiteSelect = React.createClass({
  getDefaultProps: function() {
    return {
      url: '/api/sites'
    }
  },

  getInitialState: function() {
    return {
      sites: [],
      selectedSiteUuid: this.props.defaultSiteUuid
    };
  },

  componentDidMount: function() {
    $.get(this.props.url, function(result) {
      if (!this.isMounted()) return;

      this.setState(React.addons.update(this.state, {
        sites: { $set: result.sites }
      }));

      this.fireSiteChanged(this.state.selectedSiteUuid);
    }.bind(this));
  },

  handleSiteChange: function(uuid) {
    this.setState(React.addons.update(this.state, {
      selectedSiteUuid: { $set: uuid }
    }));

    this.fireSiteChanged(uuid);
  },

  fireSiteChanged: function(siteUuid) {
    this.props.onChange(_.find(this.state.sites, {uuid: siteUuid}));
  },

  render: function() {
    if (this.state.sites.length > 1)
      return (
      <div className="row">
        <div className="col pe-2">
          <label>Site</label>
        </div>
        <div className="col">
          <Select className="input-large" ref="select" clearable={false}
            value={this.state.selectedSiteUuid}
            onChange={this.handleSiteChange}
            options={this.state.sites.map(function(site) {
              return {value: site.uuid, label: site.name};
            })}>
          </Select>
        </div>
      </div>);
    else
      return null;
  },
});
