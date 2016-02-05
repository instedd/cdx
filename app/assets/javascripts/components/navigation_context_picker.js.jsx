$(document).ready(function(){
  $("#nav-context").click(function(event){
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
    event.preventDefault();
    return false;
  });

  // preserve the #context_side_bar element
  // and preserve the status of the body.show-navigation-context-picker css class
  var context_side_bar = null;
  var show_navigation_context = false;
  $(document).on("page:fetch", function() {
    context_side_bar = $('#context_side_bar');
    show_navigation_context = $("body").hasClass("show-navigation-context-picker");
  });
  $(document).on("page:change", function() {
    if (show_navigation_context) {
      $("body").addClass("show-navigation-context-picker");
    }
    if (context_side_bar) {
      $('#context_side_bar').append(context_side_bar.children());
    }
  });
});

var NavigationContextPicker = React.createClass({
  getInitialState: function() {
    return { context: this.props.context, subsitesIncluded: !this.props.context.full_context.endsWith("-!") };
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
    var new_context_url = URI(window.location.href).setSearch({context: site.uuid}).toString();
    if(showSubsites) {
      new_context_url += "-*";
    } else {
      new_context_url += "-!";
    }
    Turbolinks.visit(new_context_url);
  },

  render: function() {
    // since the picker tracks the selected state
    // there is no need to update the properties
    return (
      <div>
        <SitePicker selected_uuid={this.props.context.uuid} onSiteSelected={this.changeContextSite} onSubsitesToggled={this.onSubsitesToggled} subsitesIncluded={this.state.subsitesIncluded} />
      </div>
    );
  }
});
