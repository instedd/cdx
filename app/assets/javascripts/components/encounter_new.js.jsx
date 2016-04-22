var EncounterNew = React.createClass({
  getInitialState: function() {
    return {encounter: {
      institution: this.props.context.institution,
      site: null,
      patient: this.props.patient,
      samples: [],
      new_samples: [],
      test_results: [],
      assays: [],
      observations: '',
      coll_sample_type: '',
      coll_sample_other: '',
      exam_reason: '',
      tests_requested: '',
      diag_comment: '',
      treatment_weeks: 0,
      testdue_date: ''
    }};
  },

  setSite: function(site) {
    this.setState(React.addons.update(this.state, {
      encounter: {
        site: { $set: site },
        patient: { $set: this.props.patient },
        samples: { $set: [] },
        new_samples: { $set: [] },
        test_results: { $set: [] },
        assays: { $set: [] },
        observations: { $set: '' },
        coll_sample_type: { $set: '' },
        coll_sample_other: { $set: '' },
        exam_reason: { $set: '' },
        tests_requested: { $set: '' },
        diag_comment: { $set: '' },
        treatment_weeks: { $set: 0 },
        testdue_date: { $set: '' }
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
            return <EncounterForm encounter={this.state.encounter} context={this.props.context} possible_assay_results={this.props.possible_assay_results} manual_sample_entry={this.state.encounter.site.allows_manual_entry} />
          } else {
            return <FreshTestsEncounterForm encounter={this.state.encounter} context={this.props.context} possible_assay_results={this.props.possible_assay_results} manual_sample_entry={this.state.encounter.site.allows_manual_entry} />
          }
        }.bind(this))()}
      </div>
    );
  },

});
