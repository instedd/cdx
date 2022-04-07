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
