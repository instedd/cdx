AlertDisplayIncidentInfo = React.createClass({
	render: function() {

		if(this.props.edit) {
			return (
				<div className="box small gray">
					<div className = "row">
  					<div className = "col pe-3">
  						<label>Creation Date</label>
  					</div>
  					<div className = "col">
  						<label>{this.props.alert_created_at}</label>
  					</div>
  				</div>

  				< div className = "row">
  				<div className = "col pe-3">
  					<label>Incidents</label>
  				</div>
  				<div className = "col">
  					<a className = "btn-link" href={"/incidents?alert.id="+this.props.alert_info.id}><label>{this.props.alert_number_incidents}</label></a>
  				</div>
  			</div>
			  <div className = "row">
    			<div className = "col pe-3">
    				<label>Last Incident</label>
    			</div>
    			<div className = "col" id="incidents">
    				<label>{this.props.alert_last_incident} Ago</label>
    			</div>
    		</div>
      );
    } else {
	    return null;
    }
  }
});
