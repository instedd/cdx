var LoincCodeSelect = React.createClass({
  getInitialState: function() {
    return {
    loincCode : this.props.loincCode,
    assayIndex: this.props.assayIndex,
    loincInputValue: this.props.loincInputValue
     };
  },

  getDefaultProps: function() {
    return {
      className: "input-large",
      placeholder: "Search by Loinc Code",
      onLoincCodeChanged: null,
      onError: null
    };
  },

  render: function() {
    return (
    <div className="row">
      <div className="col pe-2">
        <label>Loinc Code</label>
      </div>
      <div className="col">

        <label style={{ display: "none" }}>disableautocomplete</label>
        <Select
          value={this.state.loincCode}
          className="input-xx-large"
          placeholder={this.props.placeholder}
          clearable={true}
          asyncOptions={this.search}
          autoload={false}
          onChange={this.onLoincCodeChanged}
          optionRenderer={this.renderOption}
          valueRenderer={this.renderValue}
          valueKey='id'
          cacheAsyncResults={false}
          filterOptions={this.filterOptions}>
        </Select>

        <input name={`sample[assay_attachments_attributes][${this.props.assayIndex}][loinc_code]`}
               type="hidden" value={this.state.loincInputValue} id={`sample[assay_attachments_attributes][${this.props.assayIndex}][loinc_code]`}/>

        {/*{(function(){*/}
        {/*  if (this.state.patient == null) {*/}
        {/*    return <a className="btn-add-link" href={"/patients/new?" + $.param({next_url: window.location.href})} title="Create new patient"><span className="icon-circle-plus icon-blue"></span></a>;*/}
        {/*  }*/}
        {/*}.bind(this))()}*/}

        {/*<br/>*/}
        {/*<br/>*/}

        {/*{(function(){*/}
        {/*  if (this.state.loincCode != null) {*/}
        {/*    return <PatientCard patient={this.state.patient} canEdit={true} />;*/}
        {/*  }*/}
        {/*}.bind(this))()}*/}

      </div>
    </div>);
  },

  // private

  onLoincCodeChanged: function(newValue, selection) {
    var loincCode = (selection && selection[0]) ? selection[0] : null;
    this.setState(
      function(state) {
        return React.addons.update(state, {
          loincCode: { $set : loincCode }
        })
      }
      , function() {
        if (this.props.onLoincCodeChanged) {
          this.props.onLoincCodeChanged(loincCode);
        }
      }.bind(this));
    this.setState(function(state) {
      return React.addons.update(state, {
        loincInputValue: { $set : selection[0].component }
      })
    },
      function() {
        if (this.props.onLoincCodeChanged) {
          this.props.onLoincCodeChanged(loincCode);
        }
      }.bind(this));
    },

  search: function(value, callback) {
    $.ajax({
      url: '/loinc_codes/search',
      data: { q: value },
      success: function(loincCodes) {
        callback(null, {options: loincCodes, complete: false});
        if (loincCodes.length == 0 && this.props.onError) {
          this.props.onError("No loincCodes could be found");
        }
      }.bind(this)
    });
  },

  renderOption: function(option) {
    return (<span key={option.id}>
      {option.loinc_number} - {option.component}
    </span>);
  },

  renderValue: function(option) {
    return option.component;
  },

  filterOptions: function(options, filterValue, exclude) {
    return options || [];
  },
});
