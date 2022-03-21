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
      <div id="modal_opener"  onClick={this.openTransferModal} >
      </div>
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
      includeQcInfo: false,
      selectedSamples: selectedSamplesIds(),
    };
  },

  closeModal: function(event) {
    if(event) {
      event.preventDefault();
    }

    this.props.onFinished();
  },

  transferSamples: function() {
    const data = {
      institution_id: this.state.institutionId,
      includes_qc_info: this.state.includeQcInfo,
      samples: this.state.selectedSamples.map((sample) => sample.uuid)
    }
    if (data.institution_id == null){
      $(".error").prop("hidden",false);
    }
    else{
      $.ajax({
        url: '/sample_transfers',
        method: 'POST',
        data: data,
        success: function () {
          this.closeModal();
          window.location.reload(true); // reload page to update users table
        }.bind(this)
      });
    }

  },

  batchSamples: function() {
    let checkedSamples = this.state.selectedSamples
    const listItems = checkedSamples.map((sample) => this.sampleRow(sample));
    return ({listItems});
  },

  changeInstitution: function(newValue) {
    if ($(".error").prop("hidden") === false){
      $(".error").prop("hidden", true)
    } 
    this.setState({
      institutionId: newValue,
    })
  },

  sampleRow: function(sampleData) {
    return (
      <div className="col batches-samples">
        <div className="samples-row">
          <div className="samples-item transfer-data">
            { sampleData.uuid.length > 23 ?
              sampleData.uuid.substring(0, 23) + '...' :
              sampleData.uuid
            }
          </div>
          <div className="samples-item transfer-data">
            { sampleData.isolateName.length > 23 ?
              sampleData.isolateName.substring(0, 23) + '...' :
              sampleData.isolateName
            }
          </div>
        </div>
      </div>
    )
  },

  toggleQcInfo: function() {
    var oldValue = this.state.includeQcInfo;
    this.setState({
      includeQcInfo: !oldValue
    });
  },

  render: function() {
    return(
      <div className="samples-transfer-modal">
        <div className="row">
          <div className="col pe-3"><label>Samples</label></div>
          <div className="col">
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
              <span className="error" hidden> <div className="icon-error icon-red" /> An institution is required</span>
            </div>
            <div />
          </div>
        </div>
      </div>

    )
  },

});