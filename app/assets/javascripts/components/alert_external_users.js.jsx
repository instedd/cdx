var AlertExternalUser = React.createClass({
	mixins: [React.addons.LinkedStateMixin],
	getInitialState: function() {
		return {
			firstName:"", lastName:"", email:"",telephone:"", externalUsers:[],
		};
	},
	clickHandler: function() {
		externalPerson = { id:  this.state.externalUsers.length,"firstName": this.state.firstName,"lastName": this.state.lastName,"email": this.state.email,"telephone": this.state.telephone}

		//Note: maybe this might be a better way , https://facebook.github.io/react/docs/update.html
		externalUsersTemp = this.state.externalUsers;
		externalUsersTemp.push(externalPerson);
		this.setState({
			externalUsers: externalUsersTemp
		});
		this.setState({firstName: ""});
		this.setState({lastName: ""});
		this.setState({email: ""});
		this.setState({telephone: ""});
	},
	deleteClickHander: function(index) {
		TempExternalUsers = this.state.externalUsers;
		TempExternalUsers.splice(index, 1);
		this.setState({
			externalUsers: TempExternalUsers
		});

	},
	render: function() {
		return (
			<div>
				< div className = "row" id = "newuserrow" >
				<div className = "col pe-2" >
					<label>
						Ad-hoc Recipient
						</label>
					</div >

					<div className = "col" >
						<AlertCreateExternalUser firstnameLink={this.linkState('firstName')}  lastnameLink={this.linkState('lastName')} emailLink={this.linkState('email')} telephoneLink={this.linkState('telephone')} onClick={this.clickHandler}  />
					</div>
				</div>

				<AlertListExternalUser data={this.state.externalUsers} onDeleteChange={this.deleteClickHander} />
			</div>
		);
	}
});



var AlertCreateExternalUser = React.createClass({
	propTypes: {
		onClick:   React.PropTypes.func
	},
	clickHandler: function(e) {
			this.props.onClick(e.target.value);
	},
	render: function() {
		return (
			< div className = "row">

			<div className = "col" >
				<input type = "text" placeholder = "firstName"
					valueLink = {this.props.firstnameLink} name="ggg"
					pattern=".{2,255}"   />
			</div>

			<div className = "col" >
				<input type = "text" placeholder = "lastName"
					valueLink = {this.props.lastnameLink}
					pattern=".{2,255}"  />
			</div>

			<div className = "col" >
				<input type = "text" placeholder = "email"
					valueLink = {this.props.emailLink}
					pattern=".{2,255}" />
			</div>

			<div className = "col" >
				<input type = "text" placeholder = "telephone"
					valueLink = {this.props.telephoneLink}
					pattern=".{2,255}" />
			</div>

			<div className = "col" >
				<a className = "btn-link"  onClick={this.clickHandler} >Create User</a>
			</div>

		</div>
	);
}
});



var AlertListExternalUser = React.createClass({
	propTypes: {
		onDeleteChange: React.PropTypes.func.isRequired
	},
	clickHandler: function(index) {
		this.props.onDeleteChange(index);
	},
	render: function() {
		var self = this;
		var userNodes = this.props.data.map(function(eachuser,i) {
			return (
				<ExternalUser firstName={eachuser.firstName}  lastName={eachuser.lastName} email={eachuser.email}  telephone={eachuser.telephone} key={i} eachuserarrayindex={i} onClick={self.clickHandler.bind(self,i)}  />
			);
		});
		return (
			<div className="listexternalusers">
				{userNodes}
			</div>
		);
	}
});



var ExternalUser = React.createClass({
	propTypes: {
		onClick:   React.PropTypes.func
	},
	clickHandler: function(index) {
		this.props.onClick(index);
	},
	render: function() {
		return (
			< div className = "row"id = "namerow" >
			<div className = "col pe-2" >
				&nbsp;
			</div>
			<div className = "col" >
				{this.props.firstName}
			</div>
			<div className = "col" >
				{this.props.lastName}
			</div>
			<div className = "col" >
				{this.props.email}
			</div>
			<div className = "col" >
				{this.props.telephone}
			</div>
			<div className = "col" >
				<a className = "btn-link" onClick={this.clickHandler.bind(this,this.props.eachuserarrayindex)} >Delete</a>
			</div>
		</div>
	);
}
});
