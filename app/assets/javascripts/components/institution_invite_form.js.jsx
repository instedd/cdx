var InstitutionInviteForm = React.createClass({
  getInitialState: function() {
    const { institutionData } = this.props
    const { type, name } = institutionData ? institutionData : { type: 'institution', name: null }

    return {
      type: type,
      name: name,
      hasTypeError: false
    };
  },

  changeType: function(newValue) {
    var oldValue = this.state.type
    var isBlankNewValue = this.isBlank(newValue)

    this.setState({
      type: isBlankNewValue ? oldValue : newValue,
      hasTypeError: isBlankNewValue
    })
  },

  back: function() {
    this.props.onBack()
  },

  next: function() {
    if(this.isValidInput()){
      this.props.onNext(this.state)
    }
  },

  cancel: function() {
    this.props.onCancel()
  },

  isBlank: function(str) {
    return (!str || /^\s*$/.test(str));
  },

  isValidInput: function() {
    const { type, name } = this.state
    return !this.isBlank(type) && !this.isBlank(name)
  },

  setName: function(newName) {
    this.setState({
      name: newName
    })
  },

  showNameError: function() {
    const { name } = this.state
    return name != null && this.isBlank(name)
  },

  componentDidMount: function() {
    this.props.changeTitle('Invite Institution');
  },

  render: function() {
    return (
      <div>
        <div className="row">
          <div className="col pe-3"><label>Type</label></div>
          <div className="col">
            <CdxSelect name="type" items={this.props.types} value={this.state.type} onChange={this.changeType}/>
          </div>
        </div>
        { this.state.hasTypeError ?
          <div className="col">
            <span style={{ color: "red" }}>Required field</span>
          </div>
          : null
        }
        <div className="row">
          <div className="col pe-3"><label>Name</label></div>
          <div className="col">
            <input className="input-large" type="text" value={this.state.name} onChange={(e)=> {this.setName(e.currentTarget.value)}} />
          </div>
        </div>
        { this.showNameError() ?
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
              <button className="btn btn-primary" onClick={this.next} disabled={!this.isValidInput()}>Next</button>
            </div>
          </div>
        </div>
      </div>
    )
  },

});
