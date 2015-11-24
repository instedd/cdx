var DeviceSetup = React.createClass({
  getInitialState: function() {
    return {
      receiptment: '',
    };
  },

  showInstructionsModal: function() {
    this.refs.instructionsModal.show();
    event.preventDefault();
  },

  hideInstructionsModal: function() {
    this.refs.instructionsModal.hide();
    event.preventDefault();
  },


  showEmailModal: function() {
    this.setState(React.addons.update(this.state, {
      receiptment: { $set: '' }
    }));
    this.refs.emailModal.show();
    event.preventDefault();
  },

  changeReceiptment: function(event) {
    this.setState(React.addons.update(this.state, {
      receiptment: { $set: event.target.value }
    }));
  },

  sendEmail: function() {
    $.ajax({
      url: '/devices/' + this.props.device.id + '/send_setup_email',
      method: 'POST',
      data: {receiptment: this.state.receiptment},
      success: function () {
        this.closeEmailModal();
        window.location.reload(true); // reload page in order to hide secret key
      }.bind(this)
    });
    // TODO handle error maybe globally
  },

  closeEmailModal: function() {
    this.refs.emailModal.hide();
    event.preventDefault();
  },

  render: function() {
    var setup_instructions_url = this.props.device_model.setup_instructions_url;
    var setup_instructions_url_node = null;

    if (setup_instructions_url != null && setup_instructions_url != '') {
      setup_instructions_url_node = (<p>Download instructions as a <a href={this.props.device_model.setup_instructions_url} target="_blank">pdf file</a></p>)
    }

    var support_url = this.props.device_model.support_url;
    var support_url_node = null;

    if (support_url != null && support_url != '') {
      support_url_node = (<p>Visit manufacturer's <a href={this.props.device_model.support_url} target="_blank">online support</a></p>)
    } else {
      support_url_node = (<p>Manufacturer didn't provide a support url</p>)
    }

    return (
      <p>
        <a href='#' onClick={this.showInstructionsModal}>View instructions</a> on how to setup this device
        or <a href='#' onClick={this.showEmailModal}>email setup instructions to a lab operator</a>.

        <Modal ref="instructionsModal">
          <h1>
            Instructions
          </h1>

          {setup_instructions_url_node}

          {support_url_node}

          <div className="modal-footer">
            <button className="btn btn-secondary" onClick={this.hideInstructionsModal}>Close</button>
          </div>
        </Modal>

        <Modal ref="emailModal">
          <h1>
            Email instructions
          </h1>

          <label>Receiptment</label>
          <input type="text" className="input-block" value={this.state.receiptment} onChange={this.changeReceiptment} />

          <div className="modal-footer">
            <button className="btn btn-primary" onClick={this.sendEmail}>Send</button>
            <button className="btn btn-link" onClick={this.closeEmailModal}>Cancel</button>
          </div>
        </Modal>
      </p>
    );
  }
});
