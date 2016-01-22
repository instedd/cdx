var AlertExternalUser = React.createClass({
	mixins: [React.addons.LinkedStateMixin],
	getInitialState: function() {
		return {
			first_name:"", last_name:"", email:"",telephone:"", externalUsers:[]
		};
	},
	componentDidMount: function() {
		if (this.props.existingExternalUsers !=null) {
			this.setState({
				externalUsers: this.props.existingExternalUsers});
			}
		},
		clickHandler: function() {


			if (this.props.edit == true) {
				return false;
			}

			externalPerson = { id:  this.state.externalUsers.length,"first_name": this.state.first_name,"last_name": this.state.last_name,"email": this.state.email,"telephone": this.state.telephone}

			//Note: maybe this might be a better way , https://facebook.github.io/react/docs/update.html
			externalUsersTemp = this.state.externalUsers;
			externalUsersTemp.push(externalPerson);
			this.setState({
				externalUsers: externalUsersTemp
			});
			this.setState({first_name: ""});
			this.setState({last_name: ""});
			this.setState({email: ""});
			this.setState({telephone: ""});

			this.props.onChangeParentLevel(this.state.externalUsers);
		},
		deleteClickHander: function(index) {

			if (this.props.edit == true) {
				return false;
			}

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
						<AlertCreateExternalUser firstnameLink={this.linkState('first_name')}  lastnameLink={this.linkState('last_name')} emailLink={this.linkState('email')} telephoneLink={this.linkState('telephone')} onClick={this.clickHandler}  />
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
				<input type = "text" placeholder = "first name"
					valueLink = {this.props.firstnameLink} 
					id="externaluser_firstname" />
			</div>

			<div className = "col" >
				<input type = "text" placeholder = "last name"
					valueLink = {this.props.lastnameLink}
					id="externaluser_lastname" />
			</div>

			<div className = "col" >
				<input type = "text" placeholder = "email"
					valueLink = {this.props.emailLink}
					id="externaluser_email" />
			</div>

			<div className = "col" >
				<input type = "text" placeholder = "telephone"
					valueLink = {this.props.telephoneLink}
					id="externaluser_telephone" />
			</div>

			<div className = "col" >
				<a className = "btn-link"  onClick={this.clickHandler} id="newexternaluser">Create User</a>
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
				<ExternalUser first_name={eachuser.first_name}  last_name={eachuser.last_name} email={eachuser.email}  telephone={eachuser.telephone} key={i} eachuserarrayindex={i} onClick={self.clickHandler.bind(self,i)}  />
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
				{this.props.first_name}
			</div>
			<div className = "col" >
				{this.props.last_name}
			</div>
			<div className = "col" >
				{this.props.email}
			</div>
			<div className = "col" >
				{this.props.telephone}
			</div>
			<div className = "col" >
				<a className = "btn-link" onClick={this.clickHandler.bind(this,this.props.eachuserarrayindex)} id="externaluserdelete" >Delete</a>
			</div>
		</div>
	);
}
});
