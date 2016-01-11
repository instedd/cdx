
var AlertCategorySelect = React.createClass({
	mixins: [React.addons.LinkedStateMixin],
	componentDidMount: function(){	
		this.doCategoryChange('device_errors');
   
    if (this.props.edit == true) {
	
	 document.getElementById("alertname").disabled = true;
   	 document.getElementById("alertdescription").disabled = true;
document.getElementById("alertdescription").disabled = true;

document.getElementById("alertpatient").disabled = true;
document.getElementById("alertsmslimit").disabled = true;
document.getElementById("alertmessage").disabled = true;
document.getElementById("alerterrorcode").disabled = true;

 $('select').addAttr('disabled');
 //$('select').removeAttr('disabled');

//document.getElementById("alertaggregationtype").disabled = true;

/*
category_keys = Object.keys(this.props.category_types);

document.getElementById(category_keys[0]).disabled = true;
document.getElementById(category_keys[1]).disabled = true;
document.getElementById(category_keys[2]).disabled = true;
document.getElementById(category_keys[3]).disabled = true;
*/
document.getElementById("alertsite").disabled = true;
document.getElementById("alertdevice").disabled = true;
/*
document.getElementById("alertchannel").disabled = true;

document.getElementById("alertaggregationtype").disabled = true;
document.getElementById("alertaggregationfrequency").disabled = true;
document.getElementById("alertanomalietype").disabled = true;
document.getElementById("alertrole").disabled = true;
document.getElementById("alertuser").disabled = true;
*/


   }
	},
	getInitialState: function() {
		category_keys = Object.keys(this.props.category_types);
		
		return {
			// had issues with a structure such as alert1 -updating the data object field in the 'select' options library so used individual fields
			edit: this.props.edit, all_devices: this.props.devices, current_category: this.props.alert_info.category_type, nameField:this.props.alert_info.name, descriptionField: this.props.alert_info.description, siteField:"", deviceField:this.props.alert_devices, errorCodeField:"", anomalieField:"",aggregationField:this.props.alert_info.aggregation_type,aggregationFrequencyField:this.props.alert_info.aggregation_frequency,channelField:this.props.alert_info.channel_type, roleField:"", userField:"", patientField:this.props.alert_info.notify_patients, smsLimitField:this.props.alert_info.sms_limit, messageField: this.props.alert_info.message, enabledField: this.props.alert_info.enabled
		};
	},
	categoryChanged: function (e) {
   
        var val = e.currentTarget.value;
        this.doCategoryChange(val);
},
  doCategoryChange: function (val) {
	    document.getElementById(val).checked = true;
	
		document.getElementById('errorcoderow').style.display = 'none';
		document.getElementById('errorcoderow').style.visibility = 'hidden';	

		document.getElementById('anomalierow').style.display = 'none';
		document.getElementById('anomalierow').style.visibility = 'hidden';

		if (val=='device_errors') {
			var e1 = document.getElementById('errorcoderow')
			e1.style.display = 'flex';
			e1.style.visibility= 'visible';
		}

		if (val=='anomalies') {
			var e1 = document.getElementById('anomalierow')
		//	e1.style.display = 'block';
		e1.style.display = 'flex';
		e1.style.visibility= 'visible';
	}

	this.setState({
		current_category: val
	});

	
},
siteChanged: function (e) {
	this.setState({siteField: e});

    //only show devices that are in this list  
    var new_devices = [];
    
    if (e.length == 0) {
	   this.setState({all_devices: this.props.devices});
	}
	else {
	  var wantedSites = e.split(',');
	  for (var i=0; i< this.props.devices.length; i++) {
	    if  ($.inArray(this.props.devices[i].site_id.toString(), wantedSites) >= 0	 ) {
		  var aa = this.props.devices[i].site_id;
		  new_devices.push (this.props.devices[i]);
	    }	
     }
     this.setState({all_devices: new_devices});
    }


//	listDevicesUrl = "/alerts/devices"
//	AlertActions.getDevices(listDevicesUrl, e);
},
submit_error: function(errStr) {
	alert(errStr);
},
handleAlertSubmit: function(comment) {
	var current_category = this.state.current_category;

			//check using: https://github.com/github/fetch
			//http://voidcanvas.com/react-tutorial-two-way-data-binding/

			this.setState({category1: current_category});

			var new_alert_info={ name: this.state.nameField, 
				sites_info: this.state.siteField, 
				error_code: this.state.errorCodeField,
				description: this.state.descriptionField,
				category_type: this.state.current_category,
				devices_info: this.state.deviceField, 
				anomalie_type: this.state.anomalieField,
				aggregation_type: this.state.aggregationField, 
				aggregation_frequency: this.state.aggregationFrequencyField, 
				channel_type: this.state.channelField,
				roles: this.state.roleField,
				users_info: this.state.userField,
				notify_patients: this.state.patientField,
				sms_limit: this.state.smsLimitField,
				message: this.state.messageField,
				enabled: this.state.enabledField,
			};
			
			
			AlertActions.createAlert(this.props.url,new_alert_info, '/alerts/', this.submit_error);		
		/*	
			$.ajax({
				url: this.props.url,
				dataType: 'json',
				type: 'POST',
				data: {"category": this.state.current_category, "alert" : alert},
				success: function(data) {
					//   this.loadCommentsFromServer();
				}.bind(this),
				error: function(xhr, status, err) {
					console.error(this.props.url, status, err.toString());
				}.bind(this)
			});
*/
},
render: function() {
	return (
		<div>
		<form className="commentForm" onSubmit={this.handleAlertSubmit}>

        <AlertEnabled checkedLink={this.linkState('enabledField')} />

		<AlertName valueLink={this.linkState('nameField')} />

		<AlertDescription valueLink={this.linkState('descriptionField')} />

		<div className="row">
		<div className="col pe-2">
		<label>Categories</label>
		</div>
		<div className="col">
		<input type="radio" name="category_type" value={category_keys[0]}  onChange={this.categoryChanged} id={category_keys[0]} />
		<label>Anomalies</label>
		</div>
		</div>
		<div className="row">
		<div className="col pe-2">
		&nbsp;
		</div>
		<div className="col">
		<input type="radio" name="category_type" value={category_keys[1]} onChange={this.categoryChanged} id={category_keys[1]} />
		<label>Device Errors</label>
		</div>
		</div>

		<div className="row">
		<div className="col pe-2">
		&nbsp;
		</div>
		<div className="col">
		<input type="radio" name="category_type" value={category_keys[2]} onChange={this.categoryChanged} id={category_keys[2]} />
		<label>Quality Assurance</label>
		</div>
		</div>


		<div className="row">
		<div className="col pe-2">
		&nbsp;
		</div>
		<div className="col">
		<input type="radio" name="category_type" value={category_keys[3]} onChange={this.categoryChanged} id={category_keys[3]} />
		<label>Test Results</label>
		</div>
		</div>


		<AlertSite sites={this.props.sites}  value={this.state.siteField} updateValue={this.siteChanged} />
		
		<AlertDevice devices={this.state.all_devices} valueLink={this.linkState('deviceField')} />

		<AlertErrorCode valueLink={this.linkState('errorCodeField')} />

		<AlertAnomalieType anomalie_types={this.props.anomalie_types}  valueLink={this.linkState('anomalieField')}  />

		<AlertAggregation aggregation_types={this.props.aggregation_types} value={this.state.aggregationField} valueLink={this.linkState('aggregationField')}  />
		<AlertAggregationFrequency aggregation_frequencies={this.props.aggregation_frequencies}  valueLink={this.linkState('aggregationFrequencyField')} />

		<AlertChannel channel_types={this.props.channel_types}  valueLink={this.linkState('channelField')} />
		
		<AlertRole roles={this.props.roles}  valueLink={this.linkState('roleField')} />
		
		<AlertUser users={this.props.users}  valueLink={this.linkState('userField')} />
		
		<AlertPatient valueLink={this.linkState('patientField')} />
		
		<AlertSmsLimit valueLink={this.linkState('smsLimitField')} />
		
		<AlertMessage valueLink={this.linkState('messageField')} />
		
		<div className="row">
		<div className="col pe-2">
		&nbsp;
		</div>
		<div className="col">
		<input type="submit" value="Create Alert" className="btn-primary"/>
		
		<a className="btn-link" href="/alerts">Cancel</a>
		</div>

		</div>

		</form>
		</div>
		);
}
});

