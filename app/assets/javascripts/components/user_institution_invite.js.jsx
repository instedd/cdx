var AddUserLink = React.createClass({

  getInitialState: function() {
    return {
      title: 'Invite'
    };
  },

  openInviteModal: function(event) {
    this.refs.inviteModal.show();
    event.preventDefault();
  },

  closeInviteModal: function() {
    this.refs.inviteModal.hide();
  },

  componentDidMount: function () {
    if(window.location.href.indexOf('#inviteInstitutions') != -1) {
      this.openInviteModal()
    }
  },

  render: function() {
    return (<div>
      <a className="btn-add icon side-link" href='#' title="Invite users" onClick={this.openInviteModal} ><span className="icon-mail icon-white"></span></a>
      <Modal ref="inviteModal">
        <h1>{this.state.title}</h1>

        <UserInviteForm onFinished={this.closeInviteModal} roles={this.props.roles} context={this.props.context}/>
      </Modal>
    </div>);
  }
});