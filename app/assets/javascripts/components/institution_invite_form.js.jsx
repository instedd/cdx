var InstitutionInviteForm = React.createClass({
  getInitialState: function() {
    return {
      type: 'institution',
      name: '',
      hasTypeError: false,
      hasNameError: false,
      nextButtonDisabled: true
    };
  },

  changeType: function(newValue) {
    if(this.isBlank(newValue)){
      this.setState({
        hasTypeError: true,
        nextButtonDisabled: true
      });
    } else {
      this.setState({
        name: newValue,
        hasTypeError: false
      });

      if(!this.isBlank(this.state.name)){
        this.setState({
          nextButtonDisabled: false
        });
      }

    }
  },

  back: function() {
    this.props.modalPresenterStep()
  },

  next: function() {
    if(!this.state.hasTypeError && !this.state.hasNameError){
      this.props.adminInviteStep(this.state)
    }
  },

  cancel: function() {
    this.props.onFinished()
  },

  isBlank: function(str) {
    return (!str || /^\s*$/.test(str));
  },

  setName: function(newName) {
    if(this.isBlank(newName)){
      this.setState({
        hasNameError: true,
        nextButtonDisabled: true
      });
    } else {
      this.setState({
        name: newName,
        hasNameError: false
      });

      if(!this.isBlank(this.state.type)){
        this.setState({
          nextButtonDisabled: false
        });
      }

    }
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
        { this.state.hasTypeError ?
          <div className="col">
            <span style={{ color: "red" }}>Required field</span>
          </div>
          : null
        }
        <div className="row">
          <div className="col pe-3"><label>Name</label></div>
          <div className="col"><input className="input-large" type="text" onChange={(e)=> {this.setName(e.currentTarget.value)}} /></div>
        </div>
        { this.state.hasNameError ?
          <div className="col">
            <span style={{ color: "red" }}>Required field</span>
          </div>
          : null
        }
        <div className="modal-footer">
          <div className="footer-buttons-aligning">
            <div>
              <button className="btn btn-link" onClick={this.cancel}>Cancel</button>
            </div>
            <div>
              <button className="btn btn-link" onClick={this.back}>Back</button>
              <button className="btn btn-primary" onClick={this.next} disabled={this.state.nextButtonDisabled}>Next</button>
            </div>
          </div>
        </div>
      </div>
    )
  },

});