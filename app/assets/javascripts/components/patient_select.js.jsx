var PatientSelect = React.createClass({
  getInitialState: function() {
    return { patient : null };
  },

  getDefaultProps: function() {
    return {
      className: "input-large",
      placeholder: "Search by name or patient id",
      onPatientChanged: null,
      onError: null
    };
  },

  render: function() {
    return (
    <div className="row">
      <div className="col pe-2">
        <label>Patient</label>
      </div>
      <div className="col">

        <label style={{ display: "none" }}>disableautocomplete</label>
        <Select
          value={this.state.patient}
          className="input-xx-large"
          placeholder={this.props.placeholder}
          clearable={true}
          asyncOptions={this.search}
          autoload={false}
          onChange={this.onPatientChanged}
          optionRenderer={this.renderOption}
          valueRenderer={this.renderValue}
          cacheAsyncResults={false}
          filterOptions={this.filterOptions}>
        </Select>

        <br/>
        <br/>

        {(function(){
          if (this.state.patient != null) {
            return <PatientCard patient={this.state.patient} canEdit={true} />;
          }
        }.bind(this))()}

      </div>
    </div>);
  },

  // private

  onPatientChanged: function(newValue, selection) {
    var patient = (selection && selection[0]) ? selection[0] : null;

    this.setState(React.addons.update(this.state, {
      patient : { $set : patient }
    }), function() {
      if (this.props.onPatientChanged) {
        this.props.onPatientChanged(patient);
      }
    }.bind(this));
  },

  search: function(value, callback) {
    $.ajax({
      url: '/patients/search',
      data: { context: this.props.context.uuid, q: value },
      success: function(patients) {
        callback(null, {options: patients, complete: false});
        if (patients.length == 0 && this.props.onError) {
          this.props.onError("No patient could be found");
        }
      }.bind(this)
    });
  },

  renderOption: function(option) {
    return (<span key={option.id}>
      {option.name} ({option.age || "n/a"}) {option.entity_id}
    </span>);
  },

  renderValue: function(option) {
    return option.name;
  },

  filterOptions: function(options, filterValue, exclude) {
    return options || [];
  },
});
