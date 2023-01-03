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
    if (this.props.cancelFunction) {
      window[this.props.cancelFunction]();
    }
    else{
      this.refs.confirmationModal.hide();
      if (this.props.target instanceof Function ) {
        this.props.cancel_target();	
      }
    }    
  },
  
  onConfirm: function() {
    if (this.props.confirmFunction) {
      window[this.props.confirmFunction]();
    }
    else
    { 
      if (this.props.target instanceof Function ) {
        this.props.target();	
      } else {
        window[this.props.target]();
      }
      this.refs.confirmationModal.hide();
    }
  },
  
  message: function() {
    return {__html: this.props.message};
  },
  
  confirmButtonClass: function() {
    return this.props.deletion ? "btn-primary btn-danger" : "btn-primary";
  },
  
  titleClass: function() {
    return this.props.titleClass ? this.props.titleClass : "";
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
        <h1 className={this.titleClass()}>{this.modalTitle()}</h1>
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
  