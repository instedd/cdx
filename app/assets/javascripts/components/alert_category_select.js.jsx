var AlertCategorySelect = React.createClass({
	mixins: [React.addons.LinkedStateMixin],

	componentDidMount: function() {

		if ( this.props.alert_info.category_type == null ) {
			this.doCategoryChange('device_errors');
		} else {
			this.doCategoryChange(this.props.alert_info.category_type);
		}

		if (this.props.edit == true) {
			document.getElementById("alertsmslimit").disabled = true;
			document.getElementById("alertsampleid").disabled = true;
			document.getElementById("alertmessage").disabled = true;
			document.getElementById("alertsmsmessage").disabled = true;
			document.getElementById("alerterrorcode").disabled = true;
			document.getElementById("alertminthreshold").disabled = true;
			document.getElementById("alertmaxthreshold").disabled = true;
			document.getElementById("alertaggregationthresholdlimit").disabled = true;

			this.setState({
				disable_all_selects: true
			});

			this.setState({
				submit_button_text: 'Update Alert'
			});

			category_keys = Object.keys(this.props.category_types);
			document.getElementById(category_keys[0]).disabled = true;
			document.getElementById(category_keys[1]).disabled = true;
			document.getElementById(category_keys[3]).disabled = true;
			document.getElementById(category_keys[4]).disabled = true;
		} else { //new alert
			this.setState({
				disable_all_selects: false
			});
		}
	},
	getInitialState: function() {
		category_keys = Object.keys(this.props.category_types);

		return {
			// had issues with a structure such as alert1 -updating the data object field in the 'select' options library so used individual fields
			submit_button_text: 'Create Alert',
			disable_all_selects: false,
			edit: this.props.edit,
			all_devices: this.props.devices,
			all_conditions: this.props.conditions,
			all_condition_results: this.props.condition_results,
			all_condition_result_statuses: this.props.condition_result_statuses,
			current_category: this.props.alert_info.category_type,
			nameField: this.props.alert_info.name,
			descriptionField: this.props.alert_info.description,
			siteField: "",
			deviceField: this.props.alert_devices,
			conditionField: this.props.alert_conditions,
			conditionResultsField: this.props.alert_condition_results,
			conditionResultStatusesField: this.props.alert_condition_result_statuses,
			errorCodeField: "",
			anomalieField: "",
			aggregationField: this.props.alert_info.aggregation_type,
			aggregationFrequencyField: this.props.alert_info.aggregation_frequency,
			aggregation_thresholdField: this.props.alert_info.aggregation_threshold,
			channelField: this.props.alert_info.channel_type,
			roleField: this.props.alert_roles,
			userField: this.props.alert_internal_users,
			patientField: this.props.alert_info.notify_patients,
			smsLimitField: this.props.alert_info.sms_limit,
			sampleIdField: this.props.alert_info.sample_id,
			messageField: this.props.alert_info.message,
			smsMessageField: this.props.alert_info.sms_message,
			enabledField: this.props.alert_info.enabled,
			external_users:[],
			error_messages:[],
			test_result_min_thresholdField: this.props.alert_info.test_result_min_threshold,
			test_result_max_thresholdField: this.props.alert_info.test_result_max_threshold,
		};
	},
	categoryChanged: function(e) {
		var val = e.currentTarget.value;
		this.doCategoryChange(val);
	},
	doCategoryChange: function(val) {
		document.getElementById(val).checked = true;
		$('#errorcoderow').hide();
		$('#anomalierow').hide();
		$('#conditionrow').hide();
		$('#conditionresultrow').hide();
		$('#thresholdrow').hide();
		$('#utilizationefficiencyrow').hide();

		if (val == 'device_errors') {
			$('#errorcoderow').show();
		}
		else if (val == 'anomalies') {
			$('#anomalierow').show();
		}
		else if (val == 'test_results') {
			$('#conditionrow').show();
			$('#conditionresultrow').show();
			$('#thresholdrow').show();
		}
		else if (val == 'utilization_efficiency') {
				$('#utilizationefficiencyrow').show();
		}
		
		this.setState({
			current_category: val
		});


	},
	externalUsersChanged: function(updated_external_users) {
		this.setState({
			external_users: updated_external_users
		});
	},

	siteChanged: function(e) {
		this.setState({
			siteField: e
		});

		//only show devices that are in this list
		var new_devices = [];

		if (e.length == 0) {
			this.setState({
				all_devices: this.props.devices
			});
		}
		else {
			var wantedSites = e.split(',');
			for (var i = 0; i < this.props.devices.length; i++) {
				if ($.inArray(this.props.devices[i].site_id.toString(), wantedSites) >= 0) {
					var aa = this.props.devices[i].site_id;
					new_devices.push(this.props.devices[i]);
				}
			}
			this.setState({
				all_devices: new_devices
			});
		}
	},
	submit_error: function(errorArray) {

		this.setState({
			error_messages: errorArray
		});
		$('body').scrollTop(0);
	},
	AlertDeleteHandler: function() {
		var urlParam = this.props.url;
		urlParam = urlParam + '/' + this.props.alert_info.id;
		AlertActions.deleteAlert(urlParam, '/alerts/', this.submit_error);
	},
	handleAlertSubmit: function(event) {
		event.preventDefault();
		var current_category = this.state.current_category;

		var new_alert_info = {
			name: this.state.nameField,
			sites_info: this.state.siteField,
			error_code: this.state.errorCodeField,
			description: this.state.descriptionField,
			category_type: this.state.current_category,
			devices_info: this.state.deviceField,
			conditions_info: this.state.conditionField,
			condition_results_info: this.state.conditionResultsField,
			condition_results_statuses_info: this.state.conditionResultStatusesField,
			anomalie_type: this.state.anomalieField,
			aggregation_type: this.state.aggregationField,
			aggregation_frequency: this.state.aggregationFrequencyField,
			aggregation_threshold: this.state.aggregation_thresholdField,
			channel_type: this.state.channelField,
			roles: this.state.roleField,
			users_info: this.state.userField,
			notify_patients: this.state.patientField,
			sms_limit: this.state.smsLimitField,
			sample_id: this.state.sampleIdField,
			message: this.state.messageField,
			sms_message: this.state.smsMessageField,
			enabled: this.state.enabledField,
			external_users: this.state.external_users,
			test_result_min_threshold: this.state.test_result_min_thresholdField,
			test_result_max_threshold: this.state.test_result_max_thresholdField
		};

		if (this.props.edit == true) {
			var urlParam = this.props.url;
			urlParam = urlParam + '/' + this.props.alert_info.id;
			AlertActions.updateAlert(urlParam, new_alert_info, '/alerts/', this.submit_error);
		} else {
			AlertActions.createAlert(this.props.url, new_alert_info, '/alerts/', this.submit_error);
		}
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
				<FlashErrorMessages messages={this.state.error_messages} />

				<form className = "alertForm" id="new_alert" onSubmit = {this.handleAlertSubmit} >

					<input type='hidden' name='authenticity_token' value={this.props.authenticity_token} />

					<AlertEnabled checkedLink = {
							this.linkState('enabledField')
						}
						/>

					<AlertName valueLink={this.linkState('nameField')} />

					<AlertDescription valueLink = {
							this.linkState('descriptionField')
						}
						/>

					<div className="row">
						<div className="col pe-2">
							<label>Categories</label >
							</div>
							<div className="col" >
								<input type="radio" name="category_type" value={category_keys[0]}  onChange={this.categoryChanged} id={category_keys[0]} />
								<label htmlFor={category_keys[0]}>Anomalies</label>
							</div>
						</div>
						<div className="row">
							<div className="col pe-2">
								&nbsp;
							</div>
							<div className = "col" >
								<input type = "radio" name = "category_type" value = {
										category_keys[1]
									}
									onChange = {
										this.categoryChanged
									}
									id = {
										category_keys[1]
									}
									/>
								<label htmlFor={category_keys[1]}>Device Errors</label>
							</div>
						</div>

							<div className="row">
								<div className="col pe-2">
									&nbsp;
								</div>
								<div className = "col" >
									<input type = "radio" name = "category_type" value = {
											category_keys[3]
										}
										onChange = {
											this.categoryChanged
										}
										id = {
											category_keys[3]
										}
										/>
									<label htmlFor={category_keys[3]}>Test Results</label>
								</div>
							</div>


									<div className="row">
										<div className="col pe-2">
											&nbsp;
										</div>
										<div className = "col" >
											<input type = "radio" name = "category_type" value = {
													category_keys[4]
												}
												onChange = {
													this.categoryChanged
												}
												id = {
													category_keys[4]
												}
												/>
											<label htmlFor={category_keys[4]}>Utilization Efficiency</label>
										</div>
									</div>
								
								

							<AlertSite sites = {
									this.props.sites
								}
								value = {
									this.state.siteField
								}
								updateValue = {
									this.siteChanged
								}
								disable_all_selects = {
									this.state.disable_all_selects
								}
								/>

							<AlertDevice devices={this.state.all_devices} valueLink={this.linkState('deviceField')} disable_all_selects={this.state.disable_all_selects} />

              <AlertSampleId valueLink={this.linkState('sampleIdField')} />


							<AlertErrorCode valueLink = {
									this.linkState('errorCodeField')
								}
								/>

							<AlertAnomalieType anomalie_types={this.props.anomalie_types}  valueLink={this.linkState('anomalieField')} disable_all_selects={this.state.disable_all_selects} />

							<AlertCondition conditions={this.state.all_conditions} valueLink={this.linkState('conditionField')} disable_all_selects={this.state.disable_all_selects} />
							<AlertConditionResults condition_results ={this.state.all_condition_results} valueLink={this.linkState('conditionResultsField')} disable_all_selects={this.state.disable_all_selects} />
							<AlertConditionThreshold min_valueLink={this.linkState('test_result_min_thresholdField')} max_valueLink={this.linkState('test_result_max_thresholdField')} />

              	<AlertUtilizationEfficiency aggregation_frequencies={this.props.aggregation_frequencies} valueLink = {
										this.linkState('aggregation_thresholdField')
									}
									/>

							<AlertAggregation aggregation_types = {
									this.props.aggregation_types
								}
								value = {
									this.state.aggregationField
								}
								valueLink = {
									this.linkState('aggregationField')
								}
								disable_all_selects = {
									this.state.disable_all_selects
								}
								/>
							<AlertAggregationFrequency aggregation_frequencies={this.props.aggregation_frequencies}  valueLink={this.linkState('aggregationFrequencyField')} disable_all_selects={this.state.disable_all_selects} />
							<AlertAggregationThreshold valueLink={this.linkState('aggregation_thresholdField')} />

							<AlertChannel channel_types = {
									this.props.channel_types
								}
								valueLink = {
									this.linkState('channelField')
								}
								disable_all_selects = {
									this.state.disable_all_selects
								}
								/>

							<AlertRole roles={this.props.roles}  valueLink={this.linkState('roleField')} disable_all_selects={this.state.disable_all_selects} />

							<AlertUser users = {
									this.props.users
								}
								valueLink = {
									this.linkState('userField')
								}
								disable_all_selects = {
									this.state.disable_all_selects
								}
								/>


							<AlertExternalUser edit={this.props.edit} onChangeParentLevel={this.externalUsersChanged} existingExternalUsers={this.props.alert_external_users} />

							<AlertSmsLimit valueLink={this.linkState('smsLimitField')} />

							<AlertEmailMessage valueLink = {
									this.linkState('messageField')
								}
								/>

							<AlertSmsMessage valueLink = {
									this.linkState('smsMessageField')
								}
								/>

							<div className="row">
								<div className="col pe-2">
									&nbsp;
								</div>
								<div className = "col">
									<input type = "submit" value = {this.state.submit_button_text} className = "btn-primary" id="submit" />


									<a className = "btn-link" href = "/alerts">Cancel</a>
								</div>

								<div className = "col">
									<AlertDelete edit={this.props.edit} onChangeParentLevel={this.AlertDeleteHandler} />
								</div>

							</div>



						</form >
					</div>
				);
			}
		});
