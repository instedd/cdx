var SitePicker = React.createClass({
  getDefaultProps: function() {
    return {
      institutions_url: '/api/institutions',
      sites_url: '/api/sites'
    }
  },

  getInitialState: function() {
    return { sites: [], sites_tree: [], selected_site: null, query: '', subsites_selected: this.props.subsitesIncluded };
  },

  componentDidMount: function() {
    $.get(this.props.institutions_url, function(institutions_result) {
      $.get(this.props.sites_url, function(sites_result) {
        if (!this.isMounted()) return;

        var sites_and_institutions = sites_result.sites;
        _.each(sites_and_institutions, function(site) {
          site.parent_uuid = site.parent_uuid || site.institution_uuid;
        });
        _.each(institutions_result.institutions, function(institution) {
          sites_and_institutions.push(institution);
        });

        roots_and_selected = this._buildTree(sites_and_institutions, '', this.props.selected_uuid);

        this.setState(React.addons.update(this.state, {
          sites: { $set: sites_and_institutions },
          sites_tree: { $set: roots_and_selected[0] },
          selected_site: { $set: roots_and_selected[1] }
        }));
      }.bind(this));
    }.bind(this));
  },

  _siteMatch: function(site, query) {
    return _.deburr(site.name.toLowerCase()).indexOf(query) != -1;
  },

  _buildTree: function(sites, query, selected_uuid) {
    var sites_by_uuid = {};
    var roots = [];
    var selected = null;
    var matched_sites = [];
    query = _.deburr(query).toLowerCase();

    // prepares a matched_sites with all sites that match query
    // but it prepares a children property on each site for
    // building later the tree
    _.each(sites, function(site){
      if (query != '' && !this._siteMatch(site, query)) return;
      matched_sites.push(site);
      sites_by_uuid[site.uuid] = site;
      site.children = [];
      site.selected = site.uuid == selected_uuid;
      if (site.selected) {
        selected = site;
      }
    }.bind(this));

    // builds a tree with all matched_sites and with the children
    // information. If parent is not present, it is considered a root.
    // Roots may vary depending on the query argument due to non-match of parents.
    // TODO what should happen in Match1 -> NonMatch1 -> Match2 ?
    _.each(matched_sites, function(site) {
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

  // debounce: http://stackoverflow.com/a/24679479/30948
  componentWillMount: function() {
    this.handleSearchDebounced = _.debounce(function(){
      this.handleSearch.apply(this, [this.state.query]);
    }, 500);
  },

  onSearchChange: function(event) {
    this.setState(React.addons.update(this.state, {
      query: { $set: event.target.value }
    }));
    this.handleSearchDebounced();
  },

  handleSearch: function(query) {
    roots_and_selected = this._buildTree(this.state.sites, query, this.state.selected_site.uuid);
    // should not change selected site while filtering

    this.setState(React.addons.update(this.state, {
      sites_tree: { $set: roots_and_selected[0] },
    }));
  },

  onSubsiteCheckboxChange: function() {
    var oldValue = this.state.subsites_selected;
    this.setState(React.addons.update(this.state, {
      subsites_selected: { $set: !oldValue },
    }));
    this.props.onSubsitesToggled(!oldValue);
  },

  render: function() {
    return (
      <div>
        <input type="text" className="input-block" onChange={this.onSearchChange} autoFocus="true" placeholder="Search sites" />
        <input type="checkbox" id="include-subsites" onChange={this.onSubsiteCheckboxChange} checked={this.state.subsites_selected} />
        <label htmlFor="include-subsites">Selection includes all subsites</label>
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

        <a href="#" onClick={this.onSiteClick}>
          {(function(){
            if (site.children.length > 0) {
              return <button onClick={this.toggle} />;
            }
          }.bind(this))()}
          {site.name}
        </a>
        {inner}
      </li>
    );
  }
});
