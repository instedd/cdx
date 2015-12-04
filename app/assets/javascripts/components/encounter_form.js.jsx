var EncounterForm = React.createClass({
  getDefaultProps: function() {
    return {
      assayResultOptions: _.map(['positive', 'negative', 'indeterminate'], function(v){return {value: v, label: _.capitalize(v)};})
    }
  },

  getInitialState: function() {
    return {encounter: this.props.encounter};
  },

  save: function() {
    var callback = function() {
      window.location.href = '/encounters/' + this.state.encounter.id;
    };

    if (this.state.encounter.id) {
      this._ajax('PUT', '/encounters/' + this.state.encounter.id, callback);
    } else {
      this._ajax('POST', '/encounters', callback);
    }
  },

  showAddSamplesModal: function(event) {
    this.refs.addSamplesModal.show()
    event.preventDefault()
  },

  closeAddSamplesModal: function (event) {
    this.refs.addSamplesModal.hide();
    event.preventDefault();
  },

  showUnifySamplesModal: function(sample) {
    this.setState(React.addons.update(this.state, {
      unifyingSample: { $set: sample }
    }));

    this.refs.unifySamplesModal.show()
    event.preventDefault()
  },

  closeUnifySamplesModal: function (event) {
    this.refs.unifySamplesModal.hide();
    event.preventDefault();
  },

  _ajax_put: function(url, success, extra_data) {
    this._ajax('PUT', url, success, extra_data);
  },

  _ajax: function(method, url, success, extra_data) {
    var _this = this;
    $.ajax({
      url: url,
      method: method,
      data: _.extend({ encounter: JSON.stringify(this.state.encounter) }, extra_data),
      success: function (data) {
        if (data.status == 'error') {
          alert(data.message); //TODO show errors nicely
        } else {
          _this.setState(React.addons.update(_this.state, {
            encounter: { $set: data.encounter }
          }), function(){
            if (data.status == 'ok' && success) {
              success.call(_this);
            }
          });
        }
      }
    });
  },

  unifySample: function(sample) {
    this.refs.unifySamplesModal.hide();
    this._ajax_put("/encounters/merge/sample/", null, { sample_uuids: [this.state.unifyingSample.uuid, sample.uuid] });
  },

  appendSample: function(sample) {
    this.refs.addSamplesModal.hide()
    this._ajax_put("/encounters/add/sample/" + sample.uuid);
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
    this.refs.testsModal.hide()
    this._ajax_put("/encounters/add/test/" + test.uuid);
  },

  encounterChanged: function(field){
    return function(event) {
      var newValue = event.target.value;
      this.setState(React.addons.update(this.state, {
        encounter : { [field] : { $set : newValue } }
      }));
    }.bind(this);
  },

  encounterAssayChanged: function(index, field){
    return function(event) {
      var newValue;

      if (field == 'result') {
        newValue = event;
      } else if (field == 'quantitative_result') {
        newValue = parseInt(event.target.value)
        if (isNaN(newValue)) {
          newValue = null;
        }
      } else {
        newValue = event.target.value;
      }

      this.setState(React.addons.update(this.state, {
        encounter : { assays : { [index] : { [field] : { $set : newValue } } } }
      }));
    }.bind(this);
  },

  render: function() {
    var institutionSelect = <InstitutionSelect onChange={this.setInstitution} url="/encounters/institutions"/>;

    if (this.state.encounter.institution == null)
      return (<div>{institutionSelect}</div>);

    var diagnosisEditor = null;

    if (this.state.encounter.assays.length > 0) {
      diagnosisEditor = (
        <div className="row">
          <div className="col pe-2">
            <label>Diagnosis</label>
          </div>

          <div className="col assays-editor">
            {this.state.encounter.assays.map(function(assay, index){
              return (
                <div className="row" key={index}>
                  <div className="col pe-4">
                    <div className="underline">
                      <span>{assay.condition.toUpperCase()}</span>
                    </div>
                  </div>
                  <div className="col pe-3">
                    <Select value={assay.result} options={this.props.assayResultOptions} onChange={this.encounterAssayChanged(index, 'result')} clearable={false}/>
                  </div>
                  <div className="col pe-1">
                    <input type="number" className="quantitative" value={assay.quantitative_result} placeholder="Quant." onChange={this.encounterAssayChanged(index, 'quantitative_result')} />
                  </div>
                </div>
              );
            }.bind(this))}

            <textarea className="observations" value={this.state.encounter.observations} placeholder="Observations" onChange={this.encounterChanged('observations')} />
          </div>
        </div>);
    } else {
      diagnosisEditor = null;
    }


    return (
      <div>
        <FlexFullRow>
          <PatientCard patient={this.state.encounter.patient} />
        </FlexFullRow>

        {diagnosisEditor}

        <div className="row">
          <div className="col pe-2">
            <label>Samples</label>
          </div>
          <div className="col">
            <SamplesList samples={this.state.encounter.samples} onUnifySample={this.showUnifySamplesModal} />
            <p>
              <a className="btn-href" href='#' onClick={this.showAddSamplesModal}><span className="icon-add"></span> Append sample</a>
            </p>
          </div>

          <Modal ref="addSamplesModal">
            <h1>
              <a href="#" className="modal-back" onClick={this.closeAddSamplesModal}><img src="/assets/arrow-left.png"/></a>
              Add sample
            </h1>

            <AddItemSearch callback={"/encounters/search_sample?institution_uuid=" + this.state.encounter.institution.uuid} onItemChosen={this.appendSample}
              placeholder="Search by sample id"
              itemTemplate={AddItemSearchSampleTemplate}
              itemKey="uuid" />
          </Modal>

          <Modal ref="unifySamplesModal">
            <h1>
              <a href="#" className="modal-back" onClick={this.closeUnifySamplesModal}><img src="/assets/arrow-left.png"/></a>
              Unify sample
            </h1>
            <p>Unifying sample {this.state.unifyingSample ? this.state.unifyingSample.entity_ids[0] : ""}</p>

            <AddItemSearch callback={"/encounters/search_sample?institution_uuid=" + this.state.encounter.institution.uuid + "&sample_uuids=" + _.pluck(this.state.encounter.samples, 'uuid')} onItemChosen={this.unifySample}
              placeholder="Search by sample id"
              itemTemplate={AddItemSearchSampleTemplate}
              itemKey="uuid" />
          </Modal>
        </div>

        <div className="row">
          <div className="col">
            <TestResultsList testResults={this.state.encounter.test_results} /><br/>
            <a className="btn-href"  href='#' onClick={this.showTestsModal}><span className="icon-add"></span> Add tests</a>
          </div>

          <Modal ref="testsModal">
            <h1>
              <a href="#" className="modal-back" onClick={this.closeTestsModal}><img src="/assets/arrow-left.png"/></a>
              Add test
            </h1>

            <AddItemSearch callback={"/encounters/search_test?institution_uuid=" + this.state.encounter.institution.uuid} onItemChosen={this.appendTest}
              placeholder="Search by test id"
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
