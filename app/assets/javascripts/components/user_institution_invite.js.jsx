var AddUserOrInstitutionLink = React.createClass({

  getInitialState: function() {
    return {
      title: 'Invite'
    };
  },

  changeTitle: function(newTitle) {
    this.setState({
      title: newTitle
    });
  },

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
        <h1>{this.state.title}</h1>

        <ModalPresenter changeTitle={this.changeTitle} onFinished={this.closeInviteModal} institution_types= {this.props.institution_types} roles={this.props.roles} context={this.props.context} />
      </Modal>
    </div>);
  }
});

var ModalPresenter = React.createClass({
  getInitialState: function() {
    return {
      step: 'modalPresenter',
      institutionData: null
    };
  },

  modalPresenterStep: function() {
    this.setState({
      step: 'modalPresenter'
    });
  },

  adminInviteStep: function(institutionData) {
    this.setState({
      step: 'adminInviteStep',
      institutionData: institutionData
    });
  },

  userInviteStep: function() {
    this.setState({
      step: 'userInviteStep'
    });
  },

  institutionInviteStep: function (institutionData) {
    this.setState({
      step: 'institutionInviteStep',
      institutionData: institutionData
    });
  },

  closeModal: function() {
    this.props.onFinished();
  },

  changeTitle: function (newTitle){
    this.props.changeTitle(newTitle);
  },

  componentDidUpdate: function() {
    const { step } = this.state;
    if(step === 'modalPresenter'){
      this.changeTitle('Invite');
    }
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
          <UserInviteForm changeTitle={this.changeTitle}
                          onFinished={this.closeModal}
                          roles={this.props.roles}
                          context={this.props.context}
                          onBack={()=> {this.modalPresenterStep()}}/>
        );
      case 'institutionInviteStep':
        return (
          <InstitutionInviteForm changeTitle={this.changeTitle}
                                 types={this.props.institution_types}
                                 onCancel={()=> {this.closeModal()}}
                                 onBack={()=> {this.modalPresenterStep()}}
                                 onNext={(institutionData)=> {this.adminInviteStep(institutionData)}}
                                 institutionData={this.state.institutionData}/>
        );
      case 'adminInviteStep':
        return (
          <AdminInviteForm changeTitle={this.changeTitle}
                           types={this.props.institution_types}
                           onCancel={()=> {this.closeModal()}}
                           onBack={(institutionData) => { this.institutionInviteStep(institutionData)}}
                           institutionData={this.state.institutionData}/>
        );
    }
  },

});
