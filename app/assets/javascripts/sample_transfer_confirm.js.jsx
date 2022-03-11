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
      <a href="#" className="action" onClick={this.openTransferModal} >
        <div className="icon-check_circle icon-blue" /> Confirm receipt
      </a>
      <Modal ref="transferModal">
        <h1>{this.state.title}</h1>
        <SampleTransferConfirmModal onFinished={this.closeTransferModal} url={this.props.url} />
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

  render: function() {
    return(
      <form onSubmit={this.confirmTransfer}>
        <div className="samples-transfer-modal">
          <div className="modal-footer">
            <div className="footer-buttons-aligning">
              <div>
                <button id="samples-transfer-form-submit" className="btn btn-primary" type="submit">Confirm</button>
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
