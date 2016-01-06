//http://rny.io/rails/react/2014/07/31/reactjs-and-rails.html

//var AlertStore = require('../../stores/AlertStore');
//var AlertActions = require('../actions/AlertActions');


var AlertCategorySelect = React.createClass({
	mixins: [React.addons.LinkedStateMixin],
	componentDidMount: function(){
	//	document.getElementById('errorcoderow').style.visibility = 'hidden';
	//	document.getElementById('anomalierow').style.display = 'none';
		
		document.getElementById('errorcoderow').style.display = 'none';
	//	document.getElementById('errorcoderow').style.visibility = 'hidden';	
			
		document.getElementById('anomalierow').style.display = 'none';
	//	document.getElementById('anomalierow').style.visibility = 'hidden';		
	},
	getInitialState: function() {
		category_keys = Object.keys(this.props.category_types);
		return {
			// had issues with a structure such as alert1 -updating the data object field in the 'select' options library so used individual fields
			current_category: category_keys[1], alert1:{ name1: "aa"}, nameField:"", siteField:"", deviceField:"", errorCodeField:"", anomalieField:"",aggregationField:"",aggregationFrequencyField:"",channelField:"", roleField:"", userField:"", patientField:"", smsLimitField:"", messageField: "", enabledField: "false"
		};
	},
	// handleNameChange: function(e) {
		//    this.setState({nameField: e.target.value});
		//  },
		categoryChanged: function (e) {

		document.getElementById('errorcoderow').style.display = 'none';
		document.getElementById('errorcoderow').style.visibility = 'hidden';	
			
			
		//	document.getElementById('anomalierow').style.display = 'none';
		document.getElementById('anomalierow').style.display = 'none';
		document.getElementById('anomalierow').style.visibility = 'hidden';

			//	var e1 = document.getElementById('xxx')
			//   e1.style.display = (e1.style.display == 'block') ? 'none' : 'block';

			if (e.currentTarget.value=='device_errors') {
			var e1 = document.getElementById('errorcoderow')
		 	e1.style.display = 'flex';
		    e1.style.visibility= 'visible';
			}

			if (e.currentTarget.value=='anomalies') {
			var e1 = document.getElementById('anomalierow')
		//	e1.style.display = 'block';
			e1.style.display = 'flex';
		    e1.style.visibility= 'visible';
			}

			this.setState({
				current_category: e.currentTarget.value
			});

		},
		siteChanged: function (e) {
		},
		handleAlertSubmit: function(comment) {
			var current_category = this.state.current_category;

			//check using: https://github.com/github/fetch
			//http://voidcanvas.com/react-tutorial-two-way-data-binding/

			this.setState({category1: current_category});

			alert={ name: this.state.nameField, 
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
	
			
           AlertActions.createAlert(this.props.url,alert);		
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

				<div className="row">
				<div className="col pe-2">
				<label>Name</label>
				</div>
				<div className="col pe-2">
				<input type="text" placeholder="Title" name="alert[name]"  valueLink={this.linkState('nameField')}  />
				</div>
				</div>   

				<AlertDescription />

				<div className="row">
				<div className="col pe-2">
				<label>Categories</label>
				</div>
				<div className="col">
				<input type="radio" name="category_type" value={category_keys[0]}  onChange={this.categoryChanged} />
				<label>Anomalies</label>
				</div>
				</div>
				<div className="row">
				<div className="col pe-2">
				&nbsp;
				</div>
				<div className="col">
				<input type="radio" name="category_type" value={category_keys[1]} onChange={this.categoryChanged} />
				<label>Device Errors</label>
				</div>
				</div>

				<div className="row">
				<div className="col pe-2">
				&nbsp;
				</div>
				<div className="col">
				<input type="radio" name="category_type" value={category_keys[2]} onChange={this.categoryChanged} />
				<label>Quality Assurance</label>
				</div>
				</div>


				<div className="row">
				<div className="col pe-2">
				&nbsp;
				</div>
				<div className="col">
				<input type="radio" name="category_type" value={category_keys[3]} onChange={this.categoryChanged} />
				<label>Test Results</label>
				</div>
				</div>


				<AlertSite sites={this.props.sites}  valueLink={this.linkState('siteField')} onChange={this.siteChanged}/>
				
				<AlertDevice devices={this.props.devices} valueLink={this.linkState('deviceField')} />

				<AlertErrorCode valueLink={this.linkState('errorCodeField')} />

				<AlertAnomalieType anomalie_types={this.props.anomalie_types}  valueLink={this.linkState('anomalieField')} />

               	<AlertAggregation aggregation_types={this.props.aggregation_types}  valueLink={this.linkState('aggregationField')} />
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

