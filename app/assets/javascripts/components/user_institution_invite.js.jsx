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

  closeModal: function() {
    this.props.onFinished();
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
          <button className="btn btn-link" onClick={this.props.modalPresenterStep}>Back</button>
          <button className="btn btn-primary" onClick={this.sendInvitation}>Send</button>
        </div>
      </div>
    </div>);
  }
});

var InstitutionInviteForm = React.createClass({
  getInitialState: function() {
    return {
      type: null,
      name: ''
    };
  },

  changeType: function(newValue) {
    this.setState({
      type: newValue
    });
  },

  back: function() {
    this.props.modalPresenterStep()
  },

  next: function() {
    this.props.manufacturerStep()
  },

  cancel: function() {
    this.props.onFinished()
  },

  setName: function(newName) {
    this.setState({
      name: newName
    });
  },

  render: function() {
    return (
      <div>
        <div className="row">
          <div className="col pe-3"><label>Type</label></div>
          <div className="col"><CdxSelect name="type" items={this.props.types} value={this.state.type} onChange={this.changeType} /></div>
        </div>
        <div className="row">
          <div className="col pe-3"><label>Name</label></div>
          <div className="col"><input type="text" onChange={this.setName} /></div>
        </div>
        <div className="modal-footer">
          <div className="footer-buttons-aligning">
            <div>
              <button className="btn btn-link" onClick={this.cancel}>Cancel</button>
            </div>
            <div>
              <button className="btn btn-link" onClick={this.back}>Back</button>
              <button className="btn btn-primary" onClick={this.next}>Next</button>
            </div>
          </div>
        </div>
      </div>
    )
  },

});

var ManufacturerInviteForm = React.createClass({
  getInitialState: function() {
    return {
      name: '',
      email: '',
      includeMessage: false,
      message: ''
    };
  },

  back: function() {
    this.props.modalPresenterStep()
  },

  next: function() {
    this.props.userInviteStep()
  },

  setName: function(newName) {
    this.setState({
      name: newName
    });
  },

  setEmail: function(newEmail) {
    this.setState({
      email: newEmail
    });
  },

  toggleMessage: function() {
    var oldValue = this.state.includeMessage;
    this.setState({
      includeMessage: !oldValue
    });
  },

  writeMessage: function(event) {
    this.setState({
      message: event.target.value
    });
  },

  cancel: function() {
    this.props.onFinished()
  },

  render: function() {
    return (
      <div>
        <div className="row">
          <div className="col pe-3"><label>Name</label></div>
          <div className="col"><input type="text" onChange={this.setName} /></div>
        </div>
        <div className="row">
          <div className="col pe-3"><label>Email</label></div>
          <div className="col"><input type="text" onChange={this.setEmail} /></div>
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
            <div>
              <button className="btn btn-link" onClick={this.cancel}>Cancel</button>
            </div>
            <div>
              <button className="btn btn-primary" onClick={this.next}>Send</button>
            </div>
          </div>
        </div>
      </div>
    )
  },

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

  render: function() {
    const { step } = this.state;
    switch (step) {
      case 'modalPresenter':
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