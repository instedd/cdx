var EncounterNew = React.createClass({
  getInitialState: function() {
    return {encounter: {
      institution: this.props.context.institution,
      site: null,
      patient: null,
      samples: [],
      new_samples: [],
      test_results: [],
      assays: [],
      observations: ''
    }};
  },

  setSite: function(site) {
    this.setState(React.addons.update(this.state, {
      encounter: {
        site: { $set: site },
        patient: { $set: null },
        samples: { $set: [] },
        new_samples: { $set: [] },
        test_results: { $set: [] },
        assays: { $set: [] },
        observations: { $set: '' }
      }
    }));
  },

  render: function() {
    var sitesUrl = URI("/encounters/sites").query({context: this.props.context.institution.uuid});
    var siteSelect = <SiteSelect onChange={this.setSite} url={sitesUrl} defaultSiteUuid={_.get(this.props.context.site, 'uuid')} />;

    if (this.state.encounter.site == null)
      return (<div>{siteSelect}</div>);

    return (
      <div>
        {siteSelect}

        {(function(){
          if (this.props.mode == 'existing_tests') {
            return <EncounterForm encounter={this.state.encounter} context={this.props.context} />
          } else {
            return <FreshTestsEncounterForm encounter={this.state.encounter} context={this.props.context} />
          }
        }.bind(this))()}
      </div>
    );
  },

});
