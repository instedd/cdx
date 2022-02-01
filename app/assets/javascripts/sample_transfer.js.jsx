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
        <SampleTransferModal onFinished={this.closeTransferModal} context={this.props.context} institutions={this.props.institutions} samples={this.props.samples} />
      </Modal>
    </span>);
  }
});

var SampleTransferModal = React.createClass({
  getInitialState: function() {
    return {
      institutionId: null,
      includeQcInfo: null,
      selectedSamples: selectedSamplesIds()
    };
  },

  closeModal: function() {
    event.preventDefault();
    this.props.onFinished();
  },

  transferSamples: function() {
    const data = {
      institution_id: this.state.institutionId,
      samples: this.state.selectedSamples
    }
    $.ajax({
      url: '/samples/transfer_samples',
      method: 'GET',
      data: data,
      success: function () {
        this.closeModal();
        window.location.reload(true); // reload page to update users table
      }.bind(this)
    });


  },

  batchSamples: function() {
    let checkedSamples = this.state.selectedSamples
    const listItems = checkedSamples.map((sample) => this.sampleRow(sample));
    return ({listItems});
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
            { sampleData.length > 23 ?
              sampleData.substring(0, 23) + '...' :
              sampleData
            }
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
              <button className="btn btn-primary" type="button" onClick={this.transferSamples}>Transfer</button>
            </div>
            <div />
          </div>
        </div>
      </div>

    )
  },

});