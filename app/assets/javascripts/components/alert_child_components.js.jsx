


var AlertEnabled = React.createClass({
	render: function() {
		return (
			<div className="row">
			<div className="col pe-2">
			<label>Enabled</label>
			</div>
			<div className="col">
			
			<input
			type="checkbox"
			checkedLink={this.props.checkedLink} 
			/>
			<label>
			&nbsp;
			</label>
			</div>
			</div>
			);
	}
});




var AlertName = React.createClass({
	render: function() {
		return (
			<div className="row" id="namerow">
			<div className="col pe-2">
			<label>
			Name
			</label>
			</div>
			
			<div className="col">
			<input type="text" placeholder="Name" valueLink={this.props.valueLink} id="alertname"/>
			</div>
			</div>
			);
	}
});

var AlertDescription = React.createClass({
	render: function() {
		return (
			<div className="row">
			<div className="col pe-2">
			<label>Description</label>
			</div>
			<div className="col">
			<input type="text" placeholder="Description" valueLink={this.props.valueLink} id="alertdescription"/>
			</div>
			</div>
			);
	}
});


var AlertErrorCode = React.createClass({
	render: function() {
		return (
			<div className="row" id="errorcoderow">
			<div className="col pe-2">
			<label>
			Errors
			</label>
			</div>
			
			<div className="col">
			<input type="text" placeholder="All error codes will be reported" valueLink={this.props.valueLink} id="alerterrorcode"  />
			</div>
			</div>
			);
	}
});




// http://voidcanvas.com/react-tutorial-two-way-data-binding/
var AlertSite = React.createClass({	
	getDefaultProps: function(){
		return {
			multiple: true,
			name: 'selectSite',
		}
	},					
	//https://github.com/JedWatson/react-select/issues/256				
	onChange(textValue, arrayValue) {					  
		// Multi select: grab values and send array of values to valueLink
	//THURSDAY	this.props.valueLink.requestChange(_.pluck(arrayValue, 'value').join());
		
		this.props.updateValue(_.pluck(arrayValue, 'value').join());
	},
	render: function() {
		var siteOptions=[];
		
		siteOption={};
		siteOption["value"] = "";
		siteOption["label"] = "None"
		siteOptions.push(siteOption);
		
		
		for (var i = 0; i < this.props.sites.length; i++) {
			siteOption={};
			siteOption["value"] = this.props.sites[i].id;
			siteOption["label"] = this.props.sites[i].name;
			siteOptions.push(siteOption);
		}

	//THURSDAY	var { valueLink, value, onChange, ...other } = this.props;
		var { value, onChange, ...other } = this.props;
/*THURSDAY
		return (
			<div className="row">
			<div className="col pe-2">
			<label>Site</label>
			</div>
			<div className="col">
			<Select
			name="site"
			value={value || valueLink.value}
			options={siteOptions}			   
			multi={true}		
			placeholder="None"	    
			onChange={this.onChange}
			/>
			</div>
			</div>
			);
			*/
			
			return (
				<div className="row">
				<div className="col pe-2">
				<label>Site</label>
				</div>
				<div className="col">
				<Select
				name="site"
				value={value}
				options={siteOptions}			   
				multi={true}		
				placeholder="None"	    
				onChange={this.onChange}
				disabled={this.props.disable_all_selects}
				/>
				</div>
				</div>
				);
				
	}
});





var AlertDevice = React.createClass({	
	getDefaultProps: function(){
		return {
			multiple: true,
			name: 'selectDevice',
		}
	},									
	onChange(textValue, arrayValue) {					  
		// Multi select: grab values and send array of values to valueLink
		this.props.valueLink.requestChange(_.pluck(arrayValue, 'value').join());
	},
	render: function() {
		var deviceOptions=[];
		
		deviceOption={};
		deviceOption["value"] = "";
		deviceOption["label"] = "None"
		deviceOptions.push(deviceOption);
		
		
		for (var i = 0; i < this.props.devices.length; i++) {
			deviceOption={};
			deviceOption["value"] = this.props.devices[i].id;
			deviceOption["label"] = this.props.devices[i].name;
			deviceOptions.push(deviceOption);
		}

		var { valueLink, value, onChange, ...other } = this.props;
		return (
			<div className="row">
			<div className="col pe-2">
			<label>Device</label>
			</div>
			<div className="col">
			<Select
			name="device"
			value={value || valueLink.value}
			options={deviceOptions}			   
			multi={true}		
			placeholder="None"	    
			onChange={this.onChange}
			disabled={this.props.disable_all_selects}
			/>
			</div>
			</div>
			);
	}
});



// http://voidcanvas.com/react-tutorial-two-way-data-binding/
var AlertAnomalieType = React.createClass({	
	getDefaultProps: function(){
		return {
			multiple: false,
			name: 'Anomalie',
		}
	},					
	//https://github.com/JedWatson/react-select/issues/256				
	onChange(textValue, arrayValue) {					  
		this.props.valueLink.requestChange(textValue);
	},
	render: function() {
		var options=[];
		for (var i = 0; i < Object.keys(this.props.anomalie_types).length; i++) {
			option={};
			option["value"] = i;
			option["label"] = Object.keys(this.props.anomalie_types)[i];
			options.push(option);
		}

		var { valueLink, value, onChange, ...other } = this.props;
		return (
			<div className="row" id="anomalierow">
			<div className="col pe-2">
			<label>Anomalies</label>
			</div>
			<div className="col">
			<Select
			name="anomalie"
			value={value || valueLink.value}
			options={options}			   
			multi={false}			    
			onChange={this.onChange}
			disabled={this.props.disable_all_selects}
			/>
			</div>
			</div>
			);
	}
});








var AlertAggregation = React.createClass({	
	getDefaultProps: function(){
		return {
			multiple: false,
			name: 'Aggregation',
		}
	},					
	//https://github.com/JedWatson/react-select/issues/256				
	onChange(textValue, arrayValue) {					  
	//	this.props.valueLink.requestChange(textValue);
	this.props.valueLink.requestChange(arrayValue[0].label);
},
render: function() {
	var options=[];
	for (var i = 0; i < Object.keys(this.props.aggregation_types).length; i++) {
		option={};
		option["value"] = i;
		option["label"] = Object.keys(this.props.aggregation_types)[i];
		options.push(option);
	}

	var { valueLink, value, onChange, ...other } = this.props;
	return (
		<div className="row" id="aggregationrow">
		<div className="col pe-2">
		<label>Aggregation</label>
		</div>
		<div className="col">
		<Select
		name="anomalie"
		value={value || valueLink.value}
		options={options}			   
		multi={false}			    
		onChange={this.onChange}
		disabled={this.props.disable_all_selects}
		/>
		</div>
		</div>
		);
}
});



var AlertAggregationFrequency = React.createClass({	
	getDefaultProps: function(){
		return {
			multiple: false,
			name: 'Aggregation',
		}
	},					
	//https://github.com/JedWatson/react-select/issues/256				
	onChange(textValue, arrayValue) {					  
	//	this.props.valueLink.requestChange(textValue);
	this.props.valueLink.requestChange(arrayValue[0].label);
},
render: function() {
	var options=[];
	for (var i = 0; i < Object.keys(this.props.aggregation_frequencies).length; i++) {
		option={};
		option["value"] = i;
		option["label"] = Object.keys(this.props.aggregation_frequencies)[i];
		options.push(option);
	}

	var { valueLink, value, onChange, ...other } = this.props;
	return (
		<div className="row" id="aggregationfrequenciesrow">
		<div className="col pe-2">
		<label>Aggregation frequencies</label>
		</div>
		<div className="col">
		<Select
		name="anomalie"
		value={value || valueLink.value}
		options={options}			   
		multi={false}			    
		onChange={this.onChange}
		disabled={this.props.disable_all_selects}
		/>
		</div>
		</div>
		);
}
});


var AlertChannel = React.createClass({	
	getDefaultProps: function(){
		return {
			multiple: false,
			name: 'Channel',
		}
	},					
	//https://github.com/JedWatson/react-select/issues/256				
	onChange(textValue, arrayValue) {					  
	//	this.props.valueLink.requestChange(textValue);
	this.props.valueLink.requestChange(arrayValue[0].label);
},
render: function() {
	var options=[];
	for (var i = 0; i < Object.keys(this.props.channel_types).length; i++) {
		option={};
		option["value"] = i;
		option["label"] = Object.keys(this.props.channel_types)[i];
		options.push(option);
	}

	var { valueLink, value, onChange, ...other } = this.props;
	return (
		<div className="row" id="channelrow">
		<div className="col pe-2">
		<label>Channel</label>
		</div>
		<div className="col">
		<Select
		name="channel"
		value={value || valueLink.value}
		options={options}			   
		multi={false}			    
		onChange={this.onChange}
		disabled={this.props.disable_all_selects}
		/>
		</div>
		</div>
		);
}
});





// http://voidcanvas.com/react-tutorial-two-way-data-binding/
var AlertRole = React.createClass({	
	getDefaultProps: function(){
		return {
			multiple: true,
			name: 'selectrole',
		}
	},					
	//https://github.com/JedWatson/react-select/issues/256				
	onChange(textValue, arrayValue) {					  
		// Multi select: grab values and send array of values to valueLink
		this.props.valueLink.requestChange(_.pluck(arrayValue, 'value').join());
	},
	render: function() {
		var roleOptions=[];
		
		roleOption={};
		roleOption["value"] = "";
		roleOption["label"] = "None"
		roleOptions.push(roleOption);
		
		
		for (var i = 0; i < this.props.roles.length; i++) {
			roleOption={};
			roleOption["value"] = this.props.roles[i].id;
			roleOption["label"] = this.props.roles[i].name;
			roleOptions.push(roleOption);
		}

		var { valueLink, value, onChange, ...other } = this.props;
		return (
			<div className="row">
			<div className="col pe-2">
			<label>Role</label>
			</div>
			<div className="col">
			<Select
			name="role"
			value={value || valueLink.value}
			options={roleOptions}			   
			multi={true}		
			placeholder="None"	    
			onChange={this.onChange}
			disabled={this.props.disable_all_selects}
			/>
			</div>
			</div>
			);
	}
});




// http://voidcanvas.com/react-tutorial-two-way-data-binding/
var AlertUser = React.createClass({	
	getDefaultProps: function(){
		return {
			multiple: true,
			name: 'selectuser',
		}
	},					
	//https://github.com/JedWatson/react-select/issues/256				
	onChange(textValue, arrayValue) {					  
		// Multi select: grab values and send array of values to valueLink
		this.props.valueLink.requestChange(_.pluck(arrayValue, 'value').join());
	},
	render: function() {
		var userOptions=[];
		
		userOption={};
		userOption["value"] = "";
		userOption["label"] = "None"
		userOptions.push(userOption);
		
		
		for (var i = 0; i < this.props.users.length; i++) {
			userOption={};
			userOption["value"] = this.props.users[i].id;
			userOption["label"] = this.props.users[i].email;
			userOptions.push(userOption);
		}

		var { valueLink, value, onChange, ...other } = this.props;
		return (
			<div className="row">
			<div className="col pe-2">
			<label>User</label>
			</div>
			<div className="col">
			<Select
			name="user"
			value={value || valueLink.value}
			options={userOptions}			   
			multi={true}		
			placeholder="None"	    
			onChange={this.onChange}
			disabled={this.props.disable_all_selects}
			/>
			</div>
			</div>
			);
	}
});



var AlertPatient = React.createClass({
	render: function() {
		return (
			<div className="row">
			<div className="col pe-2">
			<label>All Patients</label>
			</div>
			<div className="col">
			<input
			type="checkbox"
			checkedLink={this.props.checkedLink} 
			id="alertpatient"
			/>
			<label>
			&nbsp;
			</label>
			</div>
			</div>
			);
	}
});

var AlertPatient11 = React.createClass({
	getInitialState: function() {
		return {
			isChecked: true
		};
	},
	toggleChange: function() {
		this.setState({
	      isChecked: !this.state.isChecked // flip boolean value	      
	    }, function() {
	    	var valueLink = this.valueLink('patientField');
	    	valueLink.requestChange(isChecked);
	    	
	    }.bind(this));
	},
	render: function() {
		return (
			<div className="row">
			<div className="col pe-2">
			<label>All Patients</label>
			</div>
			<div className="col">
			
			<input
			type="checkbox"
			checked={this.state.isChecked}
			
			onChange={this.toggleChange} />
			<label>
			&nbsp;
			</label>
			</div>
			</div>
			);
	}
});






var AlertSmsLimit = React.createClass({
	render: function() {
		return (
			<div className="row" id="smslimitrow">
			<div className="col pe-2">
			<label>
			SMS Per Day Limit
			</label>
			</div>
			
			<div className="col">
			<input type="text" placeholder="sms limit" valueLink={this.props.valueLink}  id="alertsmslimit"/>
			</div>
			</div>
			);
	}
});

var AlertMessage = React.createClass({
	render: function() {
		return (
			<div className="row" id="messagerow">
			<div className="col pe-2">
			<label>
			Message
			</label>
			</div>
			
			<div className="col">
			<input type="text" placeholder="message" valueLink={this.props.valueLink} id="alertmessage"/>
			</div>
			</div>
			);
	}
});


