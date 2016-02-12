var AlertUtilizationEfficiency = React.createClass({
	render: function() {
		return (
			< div className = "row" id = "utilizationefficiencyrow" >
			<div className = "col pe-2" >
				<label>TIMESPAN</label>
			</div>

			<div className = "col" >
				<input type = "text"  type="number" min="0" max="10000" placeholder = "Amount" valueLink = {
						this.props.valueLink
					}
					id = "alertutilizationefficiencynumber" />
			</div>
		</div>
	);
}
});
