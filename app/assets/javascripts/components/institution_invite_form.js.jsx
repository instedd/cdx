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
    this.props.adminInviteStep()
  },

  cancel: function() {
    this.props.onFinished()
  },

  setName: function(newName) {
    this.setState({
      name: newName
    });
  },

  componentDidMount: function() {
    this.props.changeTitle('Invite Institution');
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