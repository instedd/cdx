var ConfirmationModal = React.createClass({

  modalTitle: function() {
    return this.props.title || "Confirmation";
  },

  cancelMessage: function() {
    return this.props.cancelMessage || "Cancel";
  },

  confirmMessage: function() {
    return this.props.confirmMessage || "Confirm";
  },

  componentDidMount: function() {
    this.refs.confirmationModal.show();
  },

  onCancel: function() {
    this.refs.confirmationModal.hide();
  },

  onConfirm: function() {
    window[this.props.target]();
    this.refs.confirmationModal.hide();
  },

  message: function() {
    return {__html: this.props.message};
  },

  render: function() {
    return (
      <Modal ref="confirmationModal" show="true">
        <h2>{this.modalTitle()}</h2>
        <div className="modal-content" dangerouslySetInnerHTML={this.message()}>
        </div>
        <div className="modal-buttons button-actions">
          <button type="button" className="btn-secondary" onClick={this.onCancel}>{this.cancelMessage()}</button>
          <button type="button" className="btn-primary pull-right" onClick={this.onConfirm}>{this.confirmMessage()}</button>
        </div>
      </Modal>
    );
  }
});
