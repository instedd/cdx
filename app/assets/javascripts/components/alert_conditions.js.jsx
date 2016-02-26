
var AlertCondition = React.createClass({
	getDefaultProps: function(){
		return {
			multiple: true,
			name: 'selectCondition'
		}
	},
	onChange(textValue, arrayValue) {
		// Multi select: grab values and send array of values to valueLink
		this.props.valueLink.requestChange(_.pluck(arrayValue, 'value').join());
	},
	render: function() {
		var conditionOptions = [];

		conditionOption = {};
		conditionOption["value"] = "";
		conditionOption["label"] = "All"
		conditionOptions.push(conditionOption);

		for (var i = 0; i < this.props.conditions.length; i++) {
			conditionOption = {};
			conditionOption["value"] = this.props.conditions[i].id;
			conditionOption["label"] = this.props.conditions[i].name;
			conditionOptions.push(conditionOption);
		}

		var {
			valueLink,
			value,
			onChange,
			...other
		} = this.props;
		return (
			<div className = "row" id = "conditionrow">
				<div className = "col pe-3" >
					<label>Conditions</label>
				</div>
				<div className = "col" >
					<Select
						name = "condition"
						value = {
							value || valueLink.value
						}
						options = {
							conditionOptions
						}
						multi = {
							true
						}
						placeholder = "All"
						onChange = {
							this.onChange
						}
						disabled = {
							this.props.disable_all_selects
						}
						/>
				</div>
			</div>
		);
	}
});



var AlertConditionResults = React.createClass({
	getDefaultProps: function(){
		return {
			multiple: true,
			name: 'selectConditionResults'
		}
	},
	onChange(textValue, arrayValue) {
		// Multi select: grab values and send array of values to valueLink
		this.props.valueLink.requestChange(_.pluck(arrayValue, 'value').join());
	},
	render: function() {
		var conditionOptions = [];

		conditionOption = {};
		conditionOption["value"] = "";
		conditionOption["label"] = "All"
		conditionOptions.push(conditionOption);

		for (var i = 0; i < this.props.condition_results.length; i++) {
			conditionOption = {};
			conditionOption["value"] = this.props.condition_results[i];
			conditionOption["label"] = this.props.condition_results[i];
			conditionOptions.push(conditionOption);
		}

		var {
			valueLink,
			value,
			onChange,
			...other
		} = this.props;
		return (
			<div className = "row" id = "conditionresultrow">
				<div className = "col pe-3" >
					<label>Condition Results</label>
				</div>
				<div className = "col" >
					<Select
						name = "conditionresult"
						value = {
							value || valueLink.value
						}
						options = {
							conditionOptions
						}
						multi = {
							true
						}
						placeholder = "All"
						onChange = {
							this.onChange
						}
						disabled = {
							this.props.disable_all_selects
						}
						/>
				</div>
			</div>
		);
	}
});


var AlertConditionResultStatuses = React.createClass({
	getDefaultProps: function(){
		return {
			multiple: true,
			name: 'selectConditionResultStatuses'
		}
	},
	onChange(textValue, arrayValue) {
		// Multi select: grab values and send array of values to valueLink
		this.props.valueLink.requestChange(_.pluck(arrayValue, 'value').join());
	},
	render: function() {
		var conditionOptions = [];

		conditionOption = {};
		conditionOption["value"] = "";
		conditionOption["label"] = "All"
		conditionOptions.push(conditionOption);

		for (var i = 0; i < this.props.condition_result_statuses.length; i++) {
			conditionOption = {};
			conditionOption["value"] = this.props.condition_result_statuses[i];
			conditionOption["label"] = this.props.condition_result_statuses[i];
			conditionOptions.push(conditionOption);
		}

		var {
			valueLink,
			value,
			onChange,
			...other
		} = this.props;
		return (
			<div className = "row" id = "conditionresultstatusesrow">
				<div className = "col pe-3" >
					<label>Condition Result Statuses</label>
				</div>
				<div className = "col" >
					<Select
						name = "conditionresultstatuses"
						value = {
							value || valueLink.value
						}
						options = {
							conditionOptions
						}
						multi = {
							true
						}
						placeholder = "All"
						onChange = {
							this.onChange
						}
						disabled = {
							this.props.disable_all_selects
						}
						/>
				</div>
			</div>
		);
	}
});



var AlertConditionThreshold = React.createClass({
	render: function() {
		return (
			< div className = "row" id = "thresholdrow" >
			<div className = "col pe-3" >
				<label>Threshold</label>
			</div>

			<div className = "col" >
				<input type = "text"  type="number" min="0" max="10000" placeholder = "min" valueLink = {
						this.props.min_valueLink
					}
					id = "alertminthreshold" disabled={this.props.edit} />
				&nbsp;&nbsp;&nbsp;&nbsp;
				<input type = "text"  type="number" min="0" max="10000" placeholder = "max" valueLink = {
						this.props.max_valueLink
					}
					id = "alertmaxthreshold" />
			</div>

		</div>
	);
}
});
