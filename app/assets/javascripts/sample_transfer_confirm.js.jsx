var SampleTransferConfirm = React.createClass({

  getInitialState: function() {
    return {
      title: 'Confirm receipt'
    };
  },

  openTransferModal: function(event) {
    this.refs.transferModal.show();
    event.preventDefault();
  },

  closeTransferModal: function() {
    this.refs.transferModal.hide();
  },

  render: function() {
    return (<span>
      <a href="#" className="action" onClick={this.openTransferModal} title="Confirm receipt">
        <div className="icon-check_circle icon-blue" /> Confirm receipt
      </a>
      <Modal ref="transferModal">
        <h1>{this.state.title}</h1>
        <SampleTransferConfirmModal onFinished={this.closeTransferModal} url={this.props.url} uuid={this.props.uuid} />
      </Modal>
    </span>);
  }
});

var SampleTransferConfirmModal = React.createClass({
  getInitialState: function() {
    return {
    };
  },

  closeModal: function(event) {
    if(event) {
      event.preventDefault();
    }

    this.props.onFinished();
  },

  confirmTransfer: function(event) {
    if(event) {
      event.preventDefault();
    }

    $.ajax({
      url: this.props.url,
      method: 'PATCH',
      success: function () {
        this.closeModal();
        window.location.reload(true); // reload page to update users table
      }.bind(this)
    });
  },

  checkUUID: function(event) {
    let uuidCheck = document.getElementById("uuid_check")
    let submitButton = document.getElementById("samples-transfer-form-submit")

    let value = uuidCheck.value
    if(value.length < 4 && value.match(/^[0-9a-f]*$/i)) {
      // don't show error for incomplete input as long as the format is valid
      uuidCheck.classList.remove("input-required")
      submitButton.disabled = true
      return;
    }

    let valid = value.toLowerCase() == this.props.uuid.substr(-4);

    if(valid) {
      uuidCheck.classList.remove("input-required")
      submitButton.disabled = false
    } else {
      uuidCheck.classList.add("input-required")
      submitButton.disabled = true
    }
  },

  render: function() {
    return(
      <form onSubmit={this.confirmTransfer}>
        <div className="samples-transfer-modal">
          <div className="row">
            <p>Complete the sample ID to confirm receipt.</p>
          </div>
          <div className="row">
            <div className="col pe-3"><label htmlFor="uuid_check">Sample ID</label></div>
            <div className="col">
              {this.props.uuid.substr(0, this.props.uuid.length - 4)}
              <input type="text" id="uuid_check" onChange={this.checkUUID} autoFocus autoComplete="false" size="4" minLength="4" maxLength="4" placeholder="XXXX" required />
              <span className="error"><div className="icon-error icon-red" /> Invalid sample ID</span>
            </div>
          </div>
          <div className="modal-footer">
            <div className="footer-buttons-aligning">
              <div>
                <button id="samples-transfer-form-submit" className="btn btn-primary" type="submit" disabled>Confirm</button>
                <button className="btn btn-link" type="button" onClick={this.closeModal}>Cancel</button>
              </div>
              <div />
            </div>
          </div>
        </div>
      </form>
    )
  },
});
