var Sample = React.createClass({
  render: function() {
    // TODO add barcode
    // TODO add printer
    return (
    <li>
     {this.props.sample.entity_id} ({this.props.sample.institution})
    </li>);
  }
});

var TestResult = React.createClass({
  render: function() {
    test = this.props.test_result
    return (
    <li>
     {test.name} ({test.device.name})
    </li>);
  }
});

// TODO should not show institution if user has only one
var AddItemSearchSampleTemplate = React.createClass({
  render: function() {
    return (<span>{this.props.item.entity_id} ({this.props.item.institution})</span>);
  }
});

var AddItemSearchTestTemplate = React.createClass({
  render: function() {
    return (<span>{this.props.item.test_id} - {this.props.item.name} ({this.props.item.device.name})</span>);
  }
});

// samples {id: Integer, entity_id: String, institution: String }
var EncounterEdit = React.createClass({
  getInitialState: function() {
    return {encounter: this.props.encounter}
  },

  showSamplesModal: function(event) {
    this.refs.samplesModal.show()
    event.preventDefault()
  },

  closeSamplesModal: function (event) {
    this.refs.samplesModal.hide();
    event.preventDefault();
  },

  appendSample: function(sample) {
    this.setState(React.addons.update(this.state, {
      encounter : { samples : {
        $push : [sample]
      }}
    }));
    this.refs.samplesModal.hide()
    var _this = this;
    $.ajax({
      url: "/encounters/" + this.state.encounter.id + "/samples/" + sample.id,
      method: 'PUT',
      success: function (data) {
        if (data.status == 'ok')
          _this.setState(React.addons.update(_this.state, {
            encounter: { $set: data.encounter }
          }));
        // TODO handle errors
      }
    });
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
    // TODO goto server
  },

  render: function() {
    return (
    <div>
      <FlexFullRow>
        <NoPatientCard />
      </FlexFullRow>
      <FlexFullRow />

      <div className="row">
        <div className="col-p1">
          <a className="side-link btn-add" href='#' onClick={this.showSamplesModal}>+</a>
          <label>Samples</label>
        </div>
        <div className="col">
          <ul>
            {this.state.encounter.samples.map(function(sample) {
               return <Sample key={sample.id} sample={sample}/>;
            })}
          </ul>
        </div>
        <Modal ref="samplesModal">
          <a href="#" onClick={this.closeSamplesModal}>←</a>
          <h1>Add sample</h1>

          <AddItemSearch callback="/encounters/search_sample" onItemChosen={this.appendSample}
            itemTemplate={AddItemSearchSampleTemplate}
            itemKey="id" />
        </Modal>
      </div>

      <div className="row">
        <div className="col-p1">
          <a className="side-link btn-add" href='#' onClick={this.showTestsModal}>+</a>
          <label>Test results</label>
        </div>
        <div className="col">
          <ul>
            {this.state.encounter.test_results.map(function(test_result) {
               return <TestResult key={test_result.id} test_result={test_result}/>;
            })}
          </ul>
        </div>

        <Modal ref="testsModal">
          <a href="#" onClick={this.closeTestsModal}>←</a>
          <h1>Add test</h1>

          <AddItemSearch callback="/encounters/search_test" onItemChosen={this.appendTest}
            itemTemplate={AddItemSearchTestTemplate}
            itemKey="id" />
        </Modal>
      </div>
    </div>);
  }

});
