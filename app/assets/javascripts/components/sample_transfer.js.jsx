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
      listHeight: 0,
      topReached: true,
      bottomReached: false
    };
  },

  showQcWarningCheckbox: function(selectedSamples) {
    const haveQc = selectedSamples.filter((sample) => sample.existsQcReference === true).length
    const missingQuantity = selectedSamples.length - haveQc
    return (
      <div>
        {haveQc > 0 && this.includeQcInfoCheckbox()}
        {missingQuantity > 0 && this.qcInfoMessage(missingQuantity, selectedSamples)}
      </div>
    )
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
    $.ajax({
      url: '/sample_transfers',
      method: 'POST',
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

  qcInfoMessage: function(missingQuantity, selectedSamples) {
    const infoMessage = (missingQuantity > 0 && missingQuantity != selectedSamples.length)
      ? `There is no Quality Control (QC) info available for ${missingQuantity} ${missingQuantity === 1 ? 'sample' : 'samples'}`
      : "There is no Quality Control (QC) info available for these samples"

    return (
      <div className="row">
        <div className="col icon-info-outline icon-gray qc-info-message">
          <div className="notification-text">{infoMessage}</div>
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

  handleScroll: function(event) {
    const element = event.target;
    let bottom = element.scrollHeight - element.scrollTop - 10 < this.state.listHeight
    let top = element.scrollTop < 10

    this.setState({
      bottomReached: bottom,
      topReached: top
    })

  },

  includeQcInfoCheckbox: function () {
    return (<div className="row">
      <div className="col pe-3 qc-info-checkbox">
        <input id="include-qc-check" type="checkbox" checked={this.state.includeQcInfo} onChange={this.toggleQcInfo}/>
        <label htmlFor="include-qc-check">Include a copy of the QC data</label>
      </div>
    </div>)
  },

  componentDidMount: function() {
    this.setState({ listHeight: this.divElement.getDOMNode().clientHeight });
  },

   render: function() {
    return(
      <div className="samples-transfer-modal" onScroll={this.handleScroll} >
        <div className="row">
          <div className="col pe-3"><label>Samples</label></div>
            <div className={`gradients ${this.state.bottomReached ? "bottom" : "" } ${this.state.topReached ? "top" : "" } `}>
              <div className="col samples-list" ref={ (divElement) => { this.divElement = divElement } }>
                {this.batchSamples()}
              </div>
          </div>
        </div>
        <div className="row">
          <div className="col pe-3"><label>Institution</label></div>
          <div className="col"><CdxSelect name="institution" items={this.props.institutions} value={this.state.institutionId} onChange={this.changeInstitution} /></div>
        </div>
        {this.showQcWarningCheckbox(this.state.selectedSamples)}
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