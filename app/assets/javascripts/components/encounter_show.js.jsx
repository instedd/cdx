var EncounterShow = React.createClass({
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

        <div className="row">
          <div className="col pe-2">
            <label>Diagnosis</label>
          </div>
          <div className="col">
            <AssaysResultList assays={this.props.encounter.assays} />

            <p>{this.props.encounter.observations}</p>

            {(function(){
              var link_or_text = null
              if (this.props.can_update) {
                link_or_text = (<span>
                  <a href={"/encounters/" + this.props.encounter.id + "/edit"}>reviewed</a>
                </span>);
              } else {
                link_or_text = "reviewed"
              }

              if (this.props.encounter.has_dirty_diagnostic) {
                return <p><i>There are new conditions that need to be {link_or_text}.</i></p>;
                }
              }.bind(this))()}
            </div>
          </div>

          <div className="row">
            <div className="col pe-2">
              <label>Samples</label>
            </div>
            <div className="col">
              <SamplesList samples={this.props.encounter.samples} />
            </div>
          </div>

          <div className="row">
            <div className="col">
              <TestResultsList testResults={this.props.encounter.test_results} showSites={false} showDevices={true} />
            </div>
          </div>
        </div>
      );
    },

  });
