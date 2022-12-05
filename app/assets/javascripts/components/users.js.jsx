var AddUserLink = React.createClass({
  openInviteModal: function() {
    this.refs.inviteModal.show();
    event.preventDefault();
  },

  closeInviteModal: function() {
    this.refs.inviteModal.hide();
  },

  render: function() {
    return (<div>
      <a className="btn-add icon side-link" href='#' title="Invite users" onClick={this.openInviteModal} ><span className="icon-mail icon-white icon-baseline"></span></a>

      <Modal ref="inviteModal">
        <h1>Invite users</h1>

        <UserInviteForm onFinished={this.closeInviteModal} roles={this.props.roles} context={this.props.context} />
      </Modal>
    </div>);
  }
});
