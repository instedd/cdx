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

    if (data.users.length == 0) {
      data.users = [this.refs.usersList.currentSearch()];
    }

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

  addUser: function(users) {
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

  back: function () {
    this.props.onBack()
  },

  closeModal: function() {
    this.props.onFinished();
  },

  componentDidMount: function() {
    this.props.changeTitle('Invite Users');
  },

  render: function() {
    return (<div>
      <div className="row">
        <div className="col pe-3"><label>Role</label></div>
        <div className="col"><CdxSelect name="role" items={this.props.roles} value={this.state.role} onChange={this.changeRole} /></div>
      </div>

      <div className="row">
        <div className="col pe-3"><label>Users</label></div>
        <div className="col"><OptionList ref="usersList"
                                         callback={this.addUser}
                                         autocompleteCallback="/users/autocomplete"
                                         context={this.props.context}
                                         allowNonExistent={true}
                                         showInput={true}
                                         placeholder="Type email and press enter" /></div>
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
        <div className="footer-buttons-aligning">
          <button className="btn btn-link" onClick={this.back}>Back</button>
          <button className="btn btn-primary" onClick={this.sendInvitation}>Send</button>
        </div>
      </div>
    </div>);
  }
});
