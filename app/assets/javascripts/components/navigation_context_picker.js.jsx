$(document).on('ready', function(){
  function initializeContext() {
    var container = $("#context_side_bar");
    if ($("[data-react-class=NavigationContextPicker]:first").length == 0) {
      // initialize react component for context picker
      // this is done only the first time user clicks on the nav bar link
      // on other clicks even across page navigations, due to Turbolinks,
      // the component is kept alive.
      container.append(
        $("<div>")
          .attr("data-react-class", "NavigationContextPicker")
          .attr("data-react-props", container.attr("data-context-react-props"))
      )
      cdx_init_components(container);
    }
    $("body").toggleClass("show-navigation-context-picker");
    $("input:first", container).focus();
    return false;
  }
  // This is the case after a reload, or on loading the site.
  // By default it shows the sidebar as open. It does not apply if there is a saved tree state which to use
  var props = $("#context_side_bar").attr("data-context-react-props");
  if(props) {
    var sidebarOpen = JSON.parse($("#context_side_bar").attr("data-context-react-props")).context.sidebar_open;
    if (context_side_bar == null && sidebarOpen) {
      initializeContext();
    }
  }
  $(document).on('click', "#nav-context", function(event){
    initializeContext();
    event.preventDefault();
    $.ajax({
      url: '/users/update_setting',
      method: 'POST',
      data: { sidebar_open: $("body").hasClass("show-navigation-context-picker") }
    });
  });

  // preserve the #context_side_bar element
  // and preserve the status of the body.show-navigation-context-picker css class
  var context_side_bar = null;
  var show_navigation_context = sidebarOpen;
  var saveCurrentContextForNextChange = function() {
    context_side_bar = $('#context_side_bar');
    show_navigation_context = $("body").hasClass("show-navigation-context-picker");
  }
  $(document).on("page:fetch", saveCurrentContextForNextChange);
  $(document).on("page:change", function() {
    if (show_navigation_context) {
      $("body").addClass("show-navigation-context-picker");
    }
    if (context_side_bar) {
      $('#context_side_bar')
        .append(context_side_bar.children())
        .trigger("context:sync");
    }

    // history back does not triggers a page:fetch, so we need to keep track of current status
    // ideally should be before history back
    saveCurrentContextForNextChange();
  });
});

var NavigationContextPicker = React.createClass({
  buildState: function(props) {
    return { context: props.context, subsitesIncluded: !props.context.full_context.endsWith("-!") }
  },

  getInitialState: function() {
    return this.buildState(this.props);
  },

  componentDidMount: function() {
    $(document).on("context:sync", function(){
      var new_props = JSON.parse($("#context_side_bar").attr("data-context-react-props"));
      this.setState(this.buildState(new_props));
    }.bind(this));
  },

  changeContextSite: function(site) {
    this.setState(React.addons.update(this.state, {
      context: { $set: site }
    }), this.toggleSubsites(site, this.state.subsitesIncluded));
  },

  onSubsitesToggled: function(showSubsites) {
    this.setState(React.addons.update(this.state, {
      subsitesIncluded: { $set: showSubsites }
    }), this.toggleSubsites(this.state.context, showSubsites));
  },

  toggleSubsites: function(site, showSubsites) {
    var new_context_url = URI(window.location.href);
    if(showSubsites) {
      new_context_url.setSearch({context: site.uuid + "-*"});
    } else {
      new_context_url.setSearch({context: site.uuid + "-!"});
    }
    Turbolinks.visit(new_context_url.toString());
  },

  render: function() {
    // since the picker tracks the selected state
    // there is no need to update the properties
    return (
      <div>
        <SitePicker selected_uuid={this.state.context.uuid} onSiteSelected={this.changeContextSite} onSubsitesToggled={this.onSubsitesToggled} subsitesIncluded={this.state.subsitesIncluded} />
      </div>
    );
  }
});
