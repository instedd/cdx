var AdminInviteForm = React.createClass({
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

  sendInvitation: function() {
    const { institutionData } = this.props;
    const {name, email, message} = this.state;
    const data = {
      institutionData: institutionData,
      userData: {name, email},
      message: message
    }

    if(this.state.includeMessage)
      data.message = this.state.message;

    $.ajax({
      url: '/users',
      method: 'POST',
      data: data,
      success: function () {
        this.cancel();
        window.location.reload(true); // reload page to update users table
      }.bind(this)
    });

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

  componentDidMount: function() {
    this.props.changeTitle('Invite Admin');
  },

  render: function() {
    return (
      <div>
        <div className="row">
          <div className="col pe-3"><label>Name</label></div>
          <div className="col"><input type="text" onChange={(e)=> {this.setName(e.currentTarget.value)}} /></div>
        </div>
        <div className="row">
          <div className="col pe-3"><label>Email</label></div>
          <div className="col"><input type="text" onChange={(e)=> {this.setEmail(e.currentTarget.value)}} /></div>
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
              <button className="btn btn-primary" onClick={this.sendInvitation}>Send</button>
            </div>
          </div>
        </div>
      </div>
    )
  },

});
