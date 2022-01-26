var SampleTransfer = React.createClass({

  getInitialState: function() {
    return {
      title: 'Transfer samples'
    };
  },

  openTransferModal: function() {
    this.refs.transferModal.show();
    event.preventDefault();
  },

  closeTransferModal: function() {
    this.refs.transferModal.hide();
  },

  render: function() {
    return (<span>
      <button name="bulk_action" type="button" id="bulk_transfer" className="btn-link" value="print" onClick={this.openTransferModal} >
        <div className="icon-telegram btn-icon"></div>
      </button>
      <Modal ref="transferModal">
        <h1>{this.state.title}</h1>
        <SampleTransferModal onFinished={this.closeTransferModal} context={this.props.context} institutions={this.props.institutions}/>
      </Modal>
    </span>);
  }
});

var SampleTransferModal = React.createClass({
  getInitialState: function() {
    return {
      institutionId: null,
      includeQcInfo: null
    };
  },

  closeModal: function() {
    event.preventDefault();
    this.props.onFinished();
  },

  batchSamples: function() {
    const data =[{uuid:"test1", inactivationMethod: "inactivationTest1"},{uuid:"test2", inactivationMethod: "inactivationTest2"}];
    const listItems = data.map((sample) => this.sampleRow(sample));

    return (
        {listItems}
    )
  },

  changeInstitution: function(newValue) {
    this.setState({
      institutionId: newValue,
    })
  },

  sampleRow: function(sampleData) {
    return (
      <div className="col pe-7 batches-samples">
        <div className="samples-row">
          <div className="samples-item">
            {sampleData.uuid}
          </div>
        </div>
      </div>
    )
  },

  toggleQcInfo: function() {
    var oldValue = this.state.includeQcInfo;
    this.setState({
      includeMessage: !oldValue
    });
  },

  render: function() {
    return(
      <div>
        <div className="row">
          <div className="col pe-3"><label>Samples</label></div>
          <div className="col pe-7">
            {this.batchSamples()}
          </div>
        </div>
        <div className="row">
          <div className="col pe-3"><label>Institution</label></div>
          <div className="col"><CdxSelect name="institution" items={this.props.institutions} value={this.state.institutionId} onChange={this.changeInstitution} /></div>
        </div>
        <div className="row">
          <div className="col pe-3">
            <input id="include-qc-check" type="checkbox" checked={this.state.includeQcInfo} onChange={this.toggleQcInfo} />
            <label htmlFor="include-qc-check">Include a copy of the QC data</label>
          </div>
        </div>
        <div className="modal-footer">
          <div className="footer-buttons-aligning">
            <div>
              <button className="btn btn-link" onClick={this.closeModal}>Cancel</button>
              <button className="btn btn-primary">Transfer</button>
            </div>
            <div />
          </div>
        </div>
      </div>

    )
  },

});