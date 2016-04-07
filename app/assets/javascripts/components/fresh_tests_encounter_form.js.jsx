var FreshTestsEncounterForm = React.createClass(_.merge({
  render: function() {
    return (
      <div>
        <PatientSelect patient={this.state.encounter.patient} context={this.props.context} onPatientChanged={this.onPatientChanged} />

        <div className="row">
          <div className="col pe-2">
            <label>Samples</label>
          </div>
          <div className="col">
            <NewSamplesList samples={this.state.encounter.new_samples} onRemoveSample={this.removeNewSample} />

            <p>
              <a className="btn-add-link" href='#' onClick={this.addNewSamples}>
                <span className="icon-circle-plus icon-blue"></span> Add sample
              </a>
            </p>
          </div>
        </div>

        <div className="row">
          <div className="col pe-2">
            <label>Reason for Examination</label>
          </div>
          <div className="col">
            <p>
              <input onChange={this.reason_chooser(0)} type="radio" name="exam_reason" value="diag" /><label>Diagnosis</label>
              <input onChange={this.reason_chooser(1)} type="radio" name="exam_reason" value="follow" /><label>Follow-Up</label>
            </p>
          </div>
        </div>
        <div id="if_reason_diag" className="row hidden">
          <div className="col pe-2">
            <label>Comment</label>
          </div>
          <div className="col">
            <textarea name="diag_comment"></textarea>
          </div>
        </div>
        <div id="if_reason_follow" className="row hidden">
          <div className="col pe-2">
            <label>Month of Treatment</label>
          </div>
          <div className="col">
            <p>dateselector_year_month</p>
          </div>
        </div>

        <div className="row">
          <div className="col pe-2">
            <label>Tests Requested</label>
          </div>
          <div className="col">
            <ul>
              <li><label>Microscopy</label>                   <input type="checkbox" name="requested_microscopy"/>  </li>
              <li><label>Xpert MTB/RIF</label>                <input type="checkbox" name="requested_xpert"/>       </li>
              <li><label>Culture Drug susceptibility</label>  <input type="checkbox" name="requested_culture"/>     </li>
              <li><label>Line probe assay</label>             <input type="checkbox" name="requested_lineprobe"/>   </li>
              <li><label>CD4 Count</label>                    <input type="checkbox" name="requested_cd4"/>         </li>
              <li><label>Viral Load Count</label>             <input type="checkbox" name="requested_viral"/>       </li>
              <li><label>HIV 1/2 Detect</label>               <input type="checkbox" name="requested_hiv"/>         </li>
            </ul>
          </div>
        </div>

        <div className="row">
          <div className="col pe-2">
            <label>Test Due Date</label>
          </div>
          <div className="col">
            <input type="date" id="testdue_date" className="datepicker"/>
          </div>
        </div>

        <hr/>

        <FlexFullRow>
          <button type="button" className="btn-primary" onClick={this.save}>Save</button>
          <a href="/encounters/new_index" className="btn btn-link">Cancel</a>
        </FlexFullRow>

        <Modal ref="addNewSamplesModal">
          <h1>
            <a href="#" className="modal-back" onClick={this.closeAddNewSamplesModal}></a>
            Add sample
          </h1>

          <p><input type="text" className="input-block" placeholder="Sample ID" ref="manualSampleEntry" /></p>
          <p><button type="button" className="btn-primary pull-right" onClick={this.validateAndSetManualEntry}>OK</button></p>
        </Modal>

      </div>
    );
  },

  handleDPEvent: function(event, picker)
  {
    console.log(picker.startDate);
  },

  reason_chooser: function(choice)
  {
    if(choice==0)
    {
      $('#if_reason_diag').removeClass('hidden');
      $('#if_reason_follow').addClass('hidden');
    }
    else
    {
      $('#if_reason_follow').removeClass('hidden');
      $('#if_reason_diag').addClass('hidden');
    }
  },

  onPatientChanged: function(patient) {
    this.setState(React.addons.update(this.state, {
      encounter : { patient: { $set : patient } },
    }));
  },
}, BaseEncounterForm));
