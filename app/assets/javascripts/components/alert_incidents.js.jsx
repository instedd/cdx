AlertDisplayIncidentInfo = React.createClass({
	render: function() {

		if(this.props.edit) {
			return (
				<div className = "filters">
					< div className = "row">
					<div className = "col pe-2">
						<label>Incidents</label>
					</div>
					<div className = "col">
						<label>{this.props.alert_number_incidents}</label>
					</div>
				</div>
				< div className = "row">
				<div className = "col pe-2">
					<label>Last Incidents</label>
				</div>
				<div className = "col">
					<label>{this.props.alert_last_incident}</label>
				</div>
			</div>

			< div className = "row">
			<div className = "col pe-2">
				<label>Date Created</label>
			</div>
			<div className = "col">
				<label>{this.props.alert_created_at}</label>
			</div>
		</div>


	</div>
);
} else {
	return null;
}
}
});
