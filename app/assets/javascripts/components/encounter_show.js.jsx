var EncounterShow = React.createClass({
	getInitialState: function() {
		var user_email='';
		if (this.props.encounter["user"] != null) {
			user_email= this.props.encounter["user"].email
		};

    return {
      user_email: user_email
    };
  },
  render: function() {
    // TODO: Show institution

    return (
      <div>
        <div className="row">
          <div className="col pe-2">
            <label>Site</label>
          </div>
          <div className="col">
            <p>{this.props.encounter.site.name}</p>
          </div>
        </div>

        <div className="row">
          <div className="col pe-2">
            <label>Test Order ID</label>
          </div>
          <div className="col">
            <p>{this.props.encounter.uuid}</p>
          </div>
        </div>

				<div className="row">
          <div className="col pe-2">
            <label>Requested By:</label>
          </div>
          <div className="col">
            <p>{this.state.user_email}</p>
          </div>
        </div>

        <div className="row">
          <div className="col pe-2">
            <label>Reason For:</label>
          </div>
          <div className="col">
            <p>{this.props.encounter.exam_reason}</p>
          </div>
        </div>


        <div className="row">
          <div className="col pe-2">
            <label>Diagnosis Comment:</label>
          </div>
          <div className="col">
            <p>{this.props.encounter.diag_comment}</p>
          </div>
        </div>


        <div className="row">
          <div className="col pe-2">
            <label>Weeks In Treatment:</label>
          </div>
          <div className="col">
            <p>{this.props.encounter.treatment_weeks}</p>
          </div>
        </div>


        <div className="row">
          <div className="col pe-2">
            <label>Tests Requested:</label>
          </div>
          <div className="col">
            <p>{this.props.encounter.tests_requested}</p>
          </div>
        </div>


        <div className="row">
          <div className="col pe-2">
            <label>Sample Type:</label>
          </div>
          <div className="col">
            <p>{this.props.encounter.coll_sample_type}</p>
          </div>
        </div>

        <div className="row">
          <div className="col pe-2">
            <label>Sample comment:</label>
          </div>
          <div className="col">
            <p>{this.props.encounter.coll_sample_other}</p>
          </div>
        </div>

        <div className="row">
          <div className="col pe-2">
            <label>Test Due Date:</label>
          </div>
          <div className="col">
            <p>{this.props.encounter.testdue_date}</p>
          </div>
        </div>


        <FlexFullRow>
          <PatientCard patient={this.props.encounter.patient} />
        </FlexFullRow>

        <br />

        </div>
      );
    },

  });
