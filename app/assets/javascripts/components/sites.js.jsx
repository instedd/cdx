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

  componentWillReceiveProps: function(nextProps) {
    if (nextProps.selected_uuid != this.state.selected_site.uuid) {
      this.state.selected_site.selected = false;
      var nextSelected = _.find(this.state.sites, {'uuid': nextProps.selected_uuid});
      nextSelected.selected = true;

      this.setState(React.addons.update(this.state, {
        selected_site: { $set: nextSelected },
        subsites_selected: { $set: nextProps.subsitesIncluded }
      }));
    } else {
      // if selected_site has not changed, the include subsites flag might.
      this.setState(React.addons.update(this.state, {
        subsites_selected: { $set: nextProps.subsitesIncluded }
      }));
    }
  },

  _siteMatch: function(site, query) {
    return _.deburr(site.name.toLowerCase()).indexOf(query) != -1;
  },

  _buildTree: function(sites, query, selected_uuid) {
    var sites_by_uuid = {};
    var roots = [];
    var selected = null;
    var matched_sites = [];
    var exp = JSON.parse(localStorage.getItem('sidebar_state') || '{}');
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
      site.expanded = exp[site.uuid]=='open' || false;
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
    }), function() {
      this.props.onSiteSelected(site);
    }.bind(this));
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
        <input type="text" className="input-block search-sites" onChange={this.onSearchChange} autoFocus="true" placeholder="Search sites" />
        <div>
          <input type="checkbox" id="include-subsites" onChange={this.onSubsiteCheckboxChange} checked={this.state.subsites_selected} />
          <label htmlFor="include-subsites" id="include-subsites">Selection includes all subsites</label>
          <SitesTreeView sites={this.state.sites_tree} onSiteClick={this.selectSite} />
        </div>
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
    return { expanded: this.props.site.expanded };
  },

  toggle: function(event) {
    this.setState(React.addons.update(this.state, {
      expanded: { $set: !this.state.expanded }
    }));
    var zs = JSON.parse( localStorage.getItem('sidebar_state') );
    zs[ this.props.site.uuid ] = this.state.expanded?'closed':'open';
    localStorage.setItem('sidebar_state', JSON.stringify(zs) );
    event.stopPropagation();
  },

  // This handles a click on an entry in the sidebar.
  // This has been modified to do a call as jquery ajax instead of a page refresh
  onSiteClick: function(event) {
    //this.props.onSiteClick(this.props.site);
    event.preventDefault();
    var url = window.location.href.split('?')[0];
    var ctx = this.props.site.uuid;
    $('div.col.maincol').load(url+'?nav=false&context='+ctx);
    $('li').removeClass('selected');
    $('li[data-reactid*="'+this.props.site.uuid+'"]').first().addClass('selected');
    $('#nav-context').attr('title',this.props.site.name).text('at '+this.props.site.name);
  },

  render: function() {
    var site = this.props.site;
    var inner = null;

    if (site.children.length > 0 && this.state.expanded) {
      inner = (
        <ul>
        {site.children.map( function(site){
          return <SiteTreeViewNode onSiteClick={this.props.onSiteClick} key={site.uuid} site={site} />;
          }.bind(this))
        }
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
