var FreshTestsEncounterForm = React.createClass(_.merge({
	componentDidMount: function() {
   $('#sample_other').hide();
  },
  render: function() {
		var now = new Date();
		var day = ("0" + now.getDate()).slice(-2);
		var month = ("0" + (now.getMonth() + 1)).slice(-2);
		var today = now.getFullYear()+"-"+(month)+"-"+(day) ;
		
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
          <div className="col pe-2">
            <input type="radio" onChange={this.reason_clicked.bind(this,0)} checked={this.state.encounter.exam_reason == 'diag'}
              name="exam_reason" id="exam_reason_diag" value="diag"/><label htmlFor="exam_reason_diag">Diagnosis</label>
</div>
<div className="col pe-2">
            <input type="radio" onChange={this.reason_clicked.bind(this,1)} checked={this.state.encounter.exam_reason == 'follow'}
              name="exam_reason" id="exam_reason_follow" value="follow"/><label htmlFor="exam_reason_follow">Follow-Up</label>
          </div>
        </div>
          <div id="if_reason_diag" className="row">
            <div className="col pe-2">
              <label>Comment</label>
            </div>
            <div className="col">
              <textarea name="diag_comment" id="diag_comment" onChange={this.diag_comment_change}></textarea>
            </div>
          </div>

{/*         { this.state.reasonDiag ? <ReasonDiag onChange={this.diag_comment_change}/> : null }
        { this.state.reasonFollow ? <ReasonFollow onChange={this.treatmentdate_change}/> : null }
 */}
        <div className="row">
          <div className="col pe-2">
            <label>Tests Requested</label>
          </div>
          <div className="col req_tests_checks">
            <ul>
              <li><input type="checkbox" onChange={this.reqtests_change} name="microscopy" id="requested_microscopy"/><label htmlFor="requested_microscopy">Microscopy</label></li>
              <li><input type="checkbox" onChange={this.reqtests_change} name="xpert"      id="requested_xpert"/><label htmlFor="requested_xpert">Xpert MTB/RIF</label></li>
              <li><input type="checkbox" onChange={this.reqtests_change} name="culture"    id="requested_culture"/><label htmlFor="requested_culture">Culture Drug susceptibility</label></li>
              <li><input type="checkbox" onChange={this.reqtests_change} name="lineprobe"  id="requested_lineprobe"/><label htmlFor="requested_lineprobe">Line probe assay</label></li>
              <li><input type="checkbox" onChange={this.reqtests_change} name="cd4"        id="requested_cd4"/><label htmlFor="requested_cd4">CD4 Count</label></li>
              <li><input type="checkbox" onChange={this.reqtests_change} name="viral"      id="requested_viral"/><label htmlFor="requested_viral">Viral Load Count</label></li>
              <li><input type="checkbox" onChange={this.reqtests_change} name="hiv"        id="requested_hiv"/><label htmlFor="requested_hiv">HIV 1/2 Detect</label></li>
            </ul>
          </div>
        </div>

				<div id="if_reason_follow" className="row">
	        <div className="col pe-2">
	          <label>Weeks in Treatment</label>
	         </div>
	         <div className="col">
	           <input type="number" min="0" max="52" onChange={this.treatmentdate_change} id="treatment_weeks" name="treatment_weeks"/>
	         </div>
	       </div>
	
        <div className="row">
          <div className="col pe-2">
            <label>Collection Sample Type</label>
          </div>
          <div className="col">
<label>
            <select className="input-large" id="coll_sample_type" name="coll_sample_type" onChange={this.sample_type_change} datavalue={this.state.encounter.coll_sample_type}>
              <option value="">Please Select...</option>
              <option value="sputum">Sputum</option>
              <option value="blood">Blood</option>
              <option value="other">Other - Please Specify</option>
            </select>
</label>
          </div>
        </div>

        <div className="row">
          <div className="col pe-2">
           &nbsp;
          </div>
          <div className="col">
            <textarea name="sample_other" id="sample_other" onChange={this.sample_other_change}></textarea>
          </div>
        </div>


        <div className="row">
          <div className="col pe-2">
            <label>Test Due Date</label>
          </div>
          <div className="col">
            <input type="date" id="testdue_date"  min={today} onChange={this.testduedate_change} value={this.state.encounter.testdue_date}/>
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

  getInitialState: function() 
  {
      $('#if_reason_diag').hide();
      $('#if_reason_follow').hide();
      $('#sample_other').hide();
  },

  checkme: function(what)
  {
    if(this.state.encounter.tests_requested.indexOf(what) != false)
        return 'selected ';
    return '';
  },

  tests_list: function()
  {
    var tests = [];
    tests['microscopy'] = 'Microscopy';
    tests['xpert'] = 'Xpert MTB/RIF';
    tests['culture'] = 'Culture Drug susceptibility';
    tests['lineprobe'] = 'Line probe assay';
    tests['cd4'] = 'CD4 Count';
    tests['viral'] = 'Viral Load Count';
    tests['hiv'] = 'HIV 1/2 Detect';
    var tout = '';
    for(var i in tests)
    {
      tout += '<li><input type="checkbox" onChange={this.reqtests_change} name="';
      tout += i;
      tout += '" ';
      if(this.state.encounter.tests_requested.indexOf(i) != false)
        tout += 'selected ';
      tout += 'id="requested_';
      tout += i;
      tout += '"/><label htmlFor="requested_';
      tout += i;
      tout += '">';
      tout += tests[i];
      tout += '</label></li>';
    }
    return {__html: tout };
  }, 

  reqtests_change: function()
  {
    reqtests = '';
    $('.req_tests_checks input:checked').each( function(dd)
    {
      reqtests += $(this).attr('name')+'|';
    });
    console.log('ReqTests: '+reqtests);
    this.setState(React.addons.update(this.state, {
      encounter : { tests_requested: { $set : reqtests } },
    }));
  },

  diag_comment_change: function()
  {
    var xx = $('#diag_comment').val();
    this.setState(React.addons.update(this.state, {
      encounter : { diag_comment: { $set : xx } },
    }));

//anthony added
//this.state.encounter.diag_comment = xx;

  }, 

  treatmentdate_change: function()
  {
    var xx = $('#treatment_weeks').val();
    this.setState(React.addons.update(this.state, {
      encounter : { treatment_weeks: { $set : xx } },
    }));

//anthony added
//this.state.encounter.treatment_weeks = xx;
  }, 

  testduedate_change: function()
  {
    var xx = $('#testdue_date').val();
    this.setState(React.addons.update(this.state, {
      encounter : { testdue_date: { $set : xx } },
    }));

		//anthony added
		this.state.encounter.testdue_date = xx;
  },

  sample_type_change: function()
  {
    var xx = $('#coll_sample_type').val();
    if(xx=='other') $('#sample_other').show(); else $('#sample_other').hide();
    this.setState(React.addons.update(this.state, {
      encounter : { coll_sample_type: { $set : xx } },
    }));
  },
  sample_other_change: function()
  {
    var xx = $('#sample_other').val();
    this.setState(React.addons.update(this.state, {
      encounter : { coll_sample_other: { $set : xx } },
    }));
  },

  reason_clicked: function(clk)
  {
    var ths = this;
    var foo = '';
    if(clk==0)  
    {
      ths.setState({'reasonFollow': false});
      ths.setState({'reasonDiag': true});
      $('#if_reason_diag').show();
      $('#if_reason_follow').hide();
      foo = 'diag';
    }
    if(clk==1)  
    {
      ths.setState({'reasonDiag': false});
      ths.setState({'reasonFollow': true});
      $('#if_reason_follow').show();
      $('#if_reason_diag').hide();
      foo = 'follow';
    }
    ths.setState(React.addons.update(this.state, {
      encounter : { exam_reason: { $set : foo } },
    }));
  },

  onPatientChanged: function(patient) {
    this.setState(React.addons.update(this.state, {
      encounter : { patient: { $set : patient } },
    }));
  },
}, BaseEncounterForm));



var ReasonDiag = React.createClass(_.merge({
    render: function() {
        return (
          <div id="if_reason_diag" className="row">
            <div className="col pe-2">
              <label>Comment</label>
            </div>
            <div className="col">
              <textarea name="diag_comment" onChange={onChange}></textarea>
            </div>
          </div>
        );
    }
}, FreshTestsEncounterForm));

var ReasonFollow = React.createClass(_.merge({
    render: function() {
        return (
          <div id="if_reason_follow" className="row">
            <div className="col pe-2">
              <label>Weeks in Treatment</label>
            </div>
            <div className="col">
              <p><input type="date" className="datepicker_single" name="treatment_weeks" onChange={onChange}/></p>
            </div>
          </div>
        );
    }
}, FreshTestsEncounterForm));
