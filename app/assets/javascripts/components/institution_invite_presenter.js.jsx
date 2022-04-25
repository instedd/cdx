var AddInstitutionLink = React.createClass({

  getInitialState: function() {
    return {
      modalTitle: 'Invite Institution'
    };
  },

  openInviteModal: function(event) {
    this.refs.inviteModal.show();
    event.preventDefault();
  },

  closeInviteModal: function() {
    this.refs.inviteModal.hide();
  },

  changeModalTitle: function(newTitle) {
    this.setState({
      modalTitle: newTitle
    });
  },

  render: function() {
    return (<div>
      <a className="btn new-institution" onClick={this.openInviteModal}>
        <span className="icon-earth icon-white" />
        Bring other institutions on board CDx
      </a>
      <span id="institution-invitation-modal">
        <Modal ref="inviteModal">
          <h1>{this.state.modalTitle}</h1>
          <ModalPresenter changeTitle={this.changeModalTitle} onFinished={this.closeInviteModal} institution_types= {this.props.institution_types} context={this.props.context} />
        </Modal>
      </span>
    </div>);
  }
});

var ModalPresenter = React.createClass({
  getInitialState: function() {
    return {
      step: 'institutionInviteStep',
      institutionData: null
    };
  },

  adminInviteStep: function(institutionData) {
    this.setState({
      step: 'adminInviteStep',
      institutionData: institutionData
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

  render: function() {
    const { step } = this.state;
    switch (step) {
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
