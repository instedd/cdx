var EncounterNew = React.createClass({
  getInitialState: function() {
    return {encounter: {
      institution: null,
      patient: null,
      samples: [],
      test_results: [],
    }};
  },

  setInstitution: function(institution) {
    this.setState(React.addons.update(this.state, {
      encounter: {
        institution: { $set: institution },
        patient: { $set: null },
        samples: { $set: [] },
        test_results: { $set: [] },
      }
    }));
  },

  save: function() {
    this._ajax('POST', '/encounters', function() {
      window.location.href = '/encounters/' + this.state.encounter.id;
    });
  },

  showSamplesModal: function(event) {
    this.refs.samplesModal.show()
    event.preventDefault()
  },

  closeSamplesModal: function (event) {
    this.refs.samplesModal.hide();
    event.preventDefault();
  },

  _ajax_put: function(url, success) {
    this._ajax('PUT', url, success);
  },

  _ajax: function(method, url, success) {
    var _this = this;
    $.ajax({
      url: url,
      method: method,
      data: { encounter: JSON.stringify(this.state.encounter) },
      success: function (data) {
        if (data.status == 'error') {
          alert(data.message); //TODO show errors nicely
        }

        _this.setState(React.addons.update(_this.state, {
          encounter: { $set: data.encounter }
        }), function(){
          if (data.status == 'ok' && success) {
            success.call(_this);
          }
        });
      }
    });
  },

  appendSample: function(sample) {
    this.setState(React.addons.update(this.state, {
      encounter : { samples : {
        $push : [sample]
      }}
    }));
    this.refs.samplesModal.hide()
    this._ajax_put("/encounters/new/sample/" + sample.uuid);
  },

  showTestsModal: function(event) {
    this.refs.testsModal.show()
    event.preventDefault()
  },

  closeTestsModal: function(event) {
    this.refs.testsModal.hide()
    event.preventDefault()
  },

  appendTest: function(test) {
    this.setState(React.addons.update(this.state, {
      encounter : { test_results : {
        $push : [test]
      }}
    }));
    this.refs.testsModal.hide()
    this._ajax_put("/encounters/new/test/" + test.uuid);
  },

  render: function() {
    if (this.state.encounter.institution == null)
      return <div><InstitutionSelect onChange={this.setInstitution}/></div>;

    return (
      <div>
        <InstitutionSelect onChange={this.setInstitution}/>
        <FlexFullRow>
          <PatientCard patient={this.state.encounter.patient} />
        </FlexFullRow>

        <div className="row">
          <div className="col-p1">
            <a className="side-link btn-add" href='#' onClick={this.showSamplesModal}>+</a>
            <label>Samples</label>
          </div>
          <div className="col">
            <SamplesList samples={this.state.encounter.samples} />
          </div>
          <Modal ref="samplesModal">
            <a href="#" onClick={this.closeSamplesModal}>←</a>
            <h1>Add sample</h1>

            <AddItemSearch callback={"/encounters/search_sample?institution_uuid=" + this.state.encounter.institution.uuid} onItemChosen={this.appendSample}
              itemTemplate={AddItemSearchSampleTemplate}
              itemKey="uuid" />
          </Modal>
        </div>

        <div className="row">
          <div className="col-p1">
            <a className="side-link btn-add" href='#' onClick={this.showTestsModal}>+</a>
            <label>Test results</label>
          </div>
          <div className="col">
            <TestResultsList testResults={this.state.encounter.test_results} />
          </div>

          <Modal ref="testsModal">
            <a href="#" onClick={this.closeTestsModal}>←</a>
            <h1>Add test</h1>

            <AddItemSearch callback="/encounters/search_test" onItemChosen={this.appendTest}
              itemTemplate={AddItemSearchTestResultTemplate}
              itemKey="uuid" />
          </Modal>
        </div>

        <FlexFullRow>
          <button type="button" className="btn-primary" onClick={this.save}>Save</button>
        </FlexFullRow>

      </div>
    );
  },

});
