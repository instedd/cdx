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
      <a className="btn-add icon side-link" href='#' title="Invite users" onClick={this.openInviteModal} ><span className="iconw-mail"></span></a>

      <Modal ref="inviteModal">
        <h1>Invite users</h1>

        <UserInviteForm onFinished={this.closeInviteModal} roles={this.props.roles} context={this.props.context} />
      </Modal>
    </div>);
  }
});

var UserInviteForm = React.createClass({
  getInitialState: function() {
    return {
      users: [],
      role: null,
      includeMessage: false,
      message: ""
    };
  },

  sendInvitation: function() {
    var data = {
      users: this.state.users.map(function(i){return i.value}),
      role: this.state.role
    };
    if(this.state.includeMessage)
      data.message = this.state.message;
    $.ajax({
      url: '/users',
      method: 'POST',
      data: data,
      success: function () {
        this.closeModal();
        window.location.reload(true); // reload page to update users table
      }.bind(this)
    });
  },

  closeModal: function() {
    this.props.onFinished();
  },

  addUser: function(users) {
    console.log(users);
    this.setState(React.addons.update(this.state, {
      users: { $set: users }
    }));
  },

  changeRole: function(newValue) {
    this.setState(React.addons.update(this.state, {
      role: { $set: newValue }
    }));
  },

  toggleMessage: function() {
    var oldValue = this.state.includeMessage;
    this.setState(React.addons.update(this.state, {
      includeMessage: { $set: !oldValue }
    }));
  },

  writeMessage: function(event) {
    this.setState(React.addons.update(this.state, {
      message: { $set: event.target.value }
    }));
  },

  render: function() {
    return (<div>
      <div className="row">
        <div className="col pe-3"><label>Role</label></div>
        <div className="col"><CdxSelect name="role" items={this.props.roles} value={this.state.role} onChange={this.changeRole} /></div>
      </div>

      <div className="row">
        <div className="col pe-3"><label>Users</label></div>
        <div className="col"><OptionList callback={this.addUser} autocompleteCallback="/users/autocomplete" context={this.props.context} allowNonExistent={true} /></div>
      </div>

      <div className="row">
        <div>
          <input id="message-check" type="checkbox" checked={this.state.includeMessage} onChange={this.toggleMessage} />
          <label className="include-message" htmlFor="message-check">Include message</label>
        </div>
      </div>

      { this.state.includeMessage ?
        <div className="row">
          <div className="col pe-3"><label>Message</label></div>
          <div className="col"><textarea value={this.state.message} onChange={this.writeMessage} className="input-block resizeable" rows="1" /></div>
        </div> : null }

      <div className="modal-footer">
        <button className="btn btn-primary" onClick={this.sendInvitation}>Send</button>
        <button className="btn btn-link" onClick={this.closeModal}>Cancel</button>
      </div>
    </div>);
  }
});
