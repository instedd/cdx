var AddUserOrInstitutionLink = React.createClass({
  openInviteModal: function() {
    this.refs.inviteModal.show();
    event.preventDefault();
  },

  closeInviteModal: function() {
    this.refs.inviteModal.hide();
  },

  render: function() {
    return (<div>
      <a className="btn-add icon side-link" href='#' title="Invite users" onClick={this.openInviteModal} ><span className="icon-mail icon-white"></span></a>

      <Modal ref="inviteModal">
        <h1>Invite</h1>

        <ModalPresenter onFinished={this.closeInviteModal} institution_types= {this.props.institution_types} roles={this.props.roles} context={this.props.context} />
      </Modal>
    </div>);
  }
});

var ModalPresenter = React.createClass({
  getInitialState: function() {
    return {
      step: 'modalPresenter'
    };
  },

  modalPresenterStep: function() {
    this.setState({
      step: 'modalPresenter'
    });
  },

  manufacturerStep: function() {
    this.setState({
      step: 'manufacturerInviteStep'
    });
  },

  userInviteStep: function() {
    this.setState({
      step: 'userInviteStep'
    });
  },

  institutionInviteStep: function() {
    this.setState({
      step: 'institutionInviteStep'
    });
  },

  closeModal: function() {
    this.props.onFinished();
  },

  presenterForm: function() {
    return (
      <div>
        <div className="row invitation-option-card" onClick={() => {this.userInviteStep()}}>
          <div className="col pe-10 description">
            NEW USER
          </div>
          <div className="col pe-1 icon-keyboard-arrow-right icon-gray"></div>
        </div>
        <div className="row invitation-option-card" onClick={() => {this.institutionInviteStep()}}>
          <div className="col pe-10 description">
            NEW INSTITUTION
          </div>
          <div className="col pe-1 icon-keyboard-arrow-right icon-gray"></div>
        </div>
        <div className="modal-footer">
          <button className="btn btn-link" onClick={this.closeModal}>Cancel</button>
        </div>
      </div>
    )
  },

  render: function() {
    const { step } = this.state;
    switch (step) {
      case 'modalPresenter':
        return this.presenterForm();
      case 'userInviteStep':
        return (
          <UserInviteForm onFinished={this.closeModal} roles={this.props.roles} context={this.props.context} modalPresenterStep={()=> {this.modalPresenterStep()}}/>
        );
      case 'institutionInviteStep':
        return (
          <InstitutionInviteForm types={this.props.institution_types} onFinished={()=> {this.closeModal()}} modalPresenterStep={()=> {this.modalPresenterStep()}} manufacturerStep={()=> {this.manufacturerStep()}}/>
        );

      case 'manufacturerInviteStep':
        return (
          <ManufacturerInviteForm types={this.props.institution_types} onFinished={()=> {this.closeModal()}} institutionInviteStep={()=> {this.institutionInviteStep()}}/>
        );
    }
  },

});