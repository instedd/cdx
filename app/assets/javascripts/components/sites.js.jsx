var ContextSitePicker = React.createClass({
  getInitialState: function() {
    return { site: this.props.site };
  },

  changeContextSite: function(site) {
    this.setState(React.addons.update(this.state, {
      site: { $set: site }
    }));
  },

  render: function() {
    // since the picker tracks the selected state
    // there is no need to update the properties
    return (
      <div>
        <p>
        Selected: {this.state.site.name}
        </p>
        <SitePicker selected_uuid={this.props.site.uuid} onSiteSelected={this.changeContextSite} />
      </div>
    );
  }
});

var SitePicker = React.createClass({
  getDefaultProps: function() {
    return {
      url: '/api/sites'
    }
  },

  getInitialState: function() {
    return { sites: [], sites_tree: [], selected_site: null };
  },

  componentDidMount: function() {
    $.get(this.props.url, function(result) {
      if (!this.isMounted()) return;

      roots_and_selected = this._buildTree(result.sites) || this.state.selected_site;

      this.setState(React.addons.update(this.state, {
        sites: { $set: result.sites },
        sites_tree: { $set: roots_and_selected[0] },
        selected_site: { $set: roots_and_selected[1] }
      }));
    }.bind(this));
  },

  _buildTree: function(sites) {
    var sites_by_uuid = {};
    var roots = [];
    var selected = null;

    _.each(sites, function(site){
      sites_by_uuid[site.uuid] = site;
      site.children = [];
      site.selected = site.uuid == this.props.selected_uuid;
      if (site.selected) {
        selected = site;
      }
    }.bind(this));

    _.each(sites, function(site) {
      parent = sites_by_uuid[site.parent_uuid]
      if (parent) {
        parent.children.push(site)
      } else {
        roots.push(site)
      }
    });

    return [roots, selected];
  },

  selectSite: function(site) {
    if (this.state.selected_site) {
      this.state.selected_site.selected = false;
    }
    site.selected = true;

    this.setState(React.addons.update(this.state, {
      selected_site: { $set: site }
    }));

    this.props.onSiteSelected(site);
  },

  render: function() {
    return (
      <div>
        <input type="text" onChange={this.onChange} autoFocus="true" />
        <SitesTreeView sites={this.state.sites_tree} onSiteClick={this.selectSite} />
      </div>
    )
  }
});

var SitesTreeView = React.createClass({
  onSiteClick: function(site) {
    this.props.onSiteClick(site);
  },

  render: function() {
    return (
      <ul className="sites-tree-view">
      {this.props.sites.map(function(site){
        return <SiteTreeViewNode key={site.uuid} site={site} onSiteClick={this.onSiteClick}/>;
      }.bind(this))}
      </ul>
    );
  }
});

var SiteTreeViewNode = React.createClass({
  getInitialState: function() {
    return { expanded: true };
  },

  toggle: function() {
    this.setState(React.addons.update(this.state, {
      expanded: { $set: !this.state.expanded }
    }));
  },

  onSiteClick: function(event) {
    this.props.onSiteClick(this.props.site);
    event.preventDefault();
  },

  render: function() {
    var site = this.props.site;
    var inner = null;

    if (site.children.length > 0 && this.state.expanded) {
      inner = (
        <ul>
        {site.children.map(function(site){
          return <SiteTreeViewNode onSiteClick={this.props.onSiteClick} key={site.uuid} site={site} />;
        }.bind(this))}
        </ul>
      );
    }

    return (
      <li key={site.uuid} className={(this.state.expanded ? "expanded" : "") + " " + (site.selected ? "selected" : "")}>
        <button onClick={this.toggle} />

        <a href="#" onClick={this.onSiteClick}>{site.name}</a>
        {inner}
      </li>
    );
  }
});
