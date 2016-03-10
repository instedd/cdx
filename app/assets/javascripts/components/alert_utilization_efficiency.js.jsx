var AlertUtilizationEfficiency = React.createClass({
	render: function() {
		return (
			< div className = "row" id = "utilizationEfficiencyRow" >
			<div className = "col pe-2" >
				<label>TIMESPAN</label>
			</div>

			<div className = "col pe">
				<input type = "text" type="number" min="0" max="10000" placeholder = "Number" valueLink = {
						this.props.valueLink
					}
					id = "alertutilizationefficiencynumber" disabled={this.props.edit} />
			</div>
		</div>
	);
}
});
