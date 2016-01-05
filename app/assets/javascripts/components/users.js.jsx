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
      <a className="btn-add side-link ontop fix" href='#' title="Add Policy" onClick={this.openInviteModal} >+</a>

      <Modal ref="inviteModal">
        <h1>Invite users</h1>

        <UserInviteForm onFinished={this.closeInviteModal} roles={this.props.roles} />
      </Modal>
    </div>);
  }
});

var UserInviteForm = React.createClass({
  getInitialState: function() {
    return {
      users: '',
      role: null
    };
  },

  sendInvitation: function() {
    $.ajax({
      url: '/users',
      method: 'POST',
      data: {users: this.state.users, role: this.state.role},
      success: function () {
        this.closeModal();
        window.location.reload(true); // reload page to update users table
      }.bind(this)
    });
  },

  closeModal: function() {
    this.props.onFinished();
  },

  addUser: function() {
    this.setState(React.addons.update(this.state, {
      users: { $set: event.target.value }
    }));
  },

  changeRole: function(newValue) {
    console.log(newValue);
    this.setState(React.addons.update(this.state, {
      role: { $set: newValue }
    }));
  },

  render: function() {
    return (<div>
      <div className="row">
        <div className="col pe-2"><label>Role</label></div>
        <div className="col"><CdxSelect name="role" items={this.props.roles} value={this.state.role} onChange={this.changeRole} /></div>
      </div>

      <div className="row">
        <div className="col pe-2"><label>Users</label></div>
        <div className="col"><input type="text" className="input-block" value={this.state.users} onChange={this.addUser} /></div>
      </div>

      <div className="modal-footer">
        <button className="btn btn-primary" onClick={this.sendInvitation}>Send</button>
        <button className="btn btn-link" onClick={this.closeModal}>Cancel</button>
      </div>
    </div>);
  }
});
