var ConfirmationModal = React.createClass({

  modalTitle: function() {
    return this.props.title || (this.props.deletion ? "Delete confirmation" : "Confirmation");
  },

  cancelMessage: function() {
    return this.props.cancelMessage || "Cancel";
  },

  confirmMessage: function() {
    return this.props.confirmMessage || (this.props.deletion ? "Delete" : "Confirm");
  },

  componentDidMount: function() {
    this.refs.confirmationModal.show();
  },

  onCancel: function() {
    this.refs.confirmationModal.hide();
  },

  onConfirm: function() {
	if (this.props.use_without_window==true) {
	  this.props.target();	
	} else {
    window[this.props.target]();
  }
    this.refs.confirmationModal.hide();
  },

  message: function() {
    return {__html: this.props.message};
  },

  confirmButtonClass: function() {
    return this.props.deletion ? "btn-primary btn-danger" : "btn-primary";
  },

  showCancelButton: function() {
    return this.props.hideCancel != true;
  },

  render: function() {
    var cancelButton = null;
    if (this.showCancelButton()) {
      cancelButton = <button type="button" className="btn-link" onClick={this.onCancel}>{this.cancelMessage()}</button>
    }
    return (
      <Modal ref="confirmationModal" show="true">
        <h1>{this.modalTitle()}</h1>
        <div className="modal-content" dangerouslySetInnerHTML={this.message()}>
        </div>
        <div className="modal-footer button-actions">
          <button type="button" className={this.confirmButtonClass()} onClick={this.onConfirm}>{this.confirmMessage()}</button>
          { cancelButton }
        </div>
      </Modal>
    );
  }
});
