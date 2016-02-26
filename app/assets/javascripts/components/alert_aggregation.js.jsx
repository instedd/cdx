

var AlertAggregation = React.createClass({
	getDefaultProps: function(){
		return {
			multiple: false,
			name: 'Aggregation',
		}
	},
	//github.com/JedWatson/react-select/issues/256
	onChange(textValue, arrayValue) {
		//this.props.valueLink.requestChange(arrayValue[0].label);
		this.props.onChange(arrayValue[0].label);
	},
	render: function() {
		var options = [];
		for (var i = 0; i < Object.keys(this.props.aggregation_types).length; i++) {
			option = {};
			option["value"] = i;
			option["label"] = Object.keys(this.props.aggregation_types)[i];
			options.push(option);
		}

		var {
			valueLink,
			value,
			onChange,
			...other
		} = this.props;
		return (
			< div className = "row" id = "aggregationTypeRow" >
			<div className = "col pe-3" >
				<label>Aggregation Type</label>
			</div>
			<div className = "col" >
				<Select
					name = "aggregation"
					value = {
						value || this.props.aggregationFrequencyField
					}
					options = {
						options
					}
					multi = {
						false
					}
					onChange = {
						this.onChange
					}
					disabled = {
						this.props.disable_all_selects
					}
					clearable = { false }
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
	//github.com/JedWatson/react-select/issues/256
	onChange(textValue, arrayValue) {
		this.props.valueLink.requestChange(arrayValue[0].label);
	},
	render: function() {
		var options = [];
		for (var i = 0; i < Object.keys(this.props.aggregation_frequencies).length; i++) {
			option = {};
			option["value"] = i;
			option["label"] = Object.keys(this.props.aggregation_frequencies)[i];
			options.push(option);
		}

		var {
			valueLink,
			value,
			onChange,
			...other
		} = this.props;
		return (
			< div className = "row" id = "aggregationFrequenciesRow" >
			<div className = "col pe-3" >
				<label>Aggregation Frequency</label>
			</div>
			<div className = "col" >
				<Select
					name = "aggregation_frequency"
					value = {
						value || valueLink.value
					}
					options = {
						options
					}
					multi = {
						false
					}
					onChange = {
						this.onChange
					}
					disabled = {
						this.props.disable_all_selects
					}
					clearable = { false }
					/>
			</div>
		</div>
	);
}
});

var AlertAggregationThreshold = React.createClass({
	render: function() {
		return (
			< div className = "row" id = "aggregationThresholdRow" >
			<div className = "col pe-3" >
				<label>Aggregation Threshold</label>
			</div>

			<div className = "col" >
				<input type = "text"  type="number" min="0" max="10000" placeholder = "Agg Threshold" valueLink = {
						this.props.valueLink
					}
					id = "alertaggregationthresholdlimit" disabled={this.props.edit} />
			</div>
		</div>
	);
}
});
