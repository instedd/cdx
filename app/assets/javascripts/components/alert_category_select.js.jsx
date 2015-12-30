//http://rny.io/rails/react/2014/07/31/reactjs-and-rails.html

var AlertCategorySelect = React.createClass({
	mixins: [React.addons.LinkedStateMixin],
	componentDidMount: function(){
		document.getElementById('errorcoderow').style.display = 'none';
		document.getElementById('anomalierow').style.display = 'none';
	},
	getInitialState: function() {
		category_keys = Object.keys(this.props.category_types);
		return {
			// had issues with a structure such as alert1 -updating the data object field in the 'select' options library so used individual fields
			current_category: category_keys[1], alert1:{ name1: "aa"}, nameField:"", siteField:"", errorCodeField:"", anomalieField:""
		};
	},
	// handleNameChange: function(e) {
		//    this.setState({nameField: e.target.value});
		//  },
		categoryChanged: function (e) {

			document.getElementById('errorcoderow').style.display = 'none';
			document.getElementById('anomalierow').style.display = 'none';

			//	var e1 = document.getElementById('xxx')
			//   e1.style.display = (e1.style.display == 'block') ? 'none' : 'block';

			if (e.currentTarget.value=='device_errors')
			var e1 = document.getElementById('errorcoderow')
			e1.style.display = 'block';
			end

			if (e.currentTarget.value=='anomalies')
			var e1 = document.getElementById('anomalierow')
			e1.style.display = 'block';
			end

			this.setState({
				current_category: e.currentTarget.value
			});

		},
		handleAlertSubmit: function(comment) {
			var current_category = this.state.current_category;

			//check using: https://github.com/github/fetch
			//http://voidcanvas.com/react-tutorial-two-way-data-binding/

			this.setState({category1: current_category});


			alert={ name: this.state.nameField, sites_info: this.state.siteField, error_code: this.state.errorCodeField};
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
		},
		render: function() {
			return (
				<div>
				<form className="commentForm" onSubmit={this.handleAlertSubmit}>

				<div className="row">
				<div className="col pe-2">
				Name
				</div>
				<div className="col pe-2">
				<input type="text" placeholder="Title" name="alert[name]"  valueLink={this.linkState('nameField')}  />
				</div>
				</div>   

				<AlertDescription />

				<div className="row">
				<div className="col pe-2">
				&nbsp;
				</div>
				<div className="col">
				<input type="radio" name="category_type" value={category_keys[0]}  onChange={this.categoryChanged} />Anomalies
				</div>
				</div>
				<div className="row">
				<div className="col pe-2">
				&nbsp;
				</div>
				<div className="col">
				<input type="radio" name="category_type" value={category_keys[1]} onChange={this.categoryChanged} />Device Errors
				</div>
				</div>

				<div className="row">
				<div className="col pe-2">
				&nbsp;
				</div>
				<div className="col">
				<input type="radio" name="category_type" value={category_keys[2]} onChange={this.categoryChanged} />Quality Assurance
				</div>
				</div>


				<div className="row">
				<div className="col pe-2">
				&nbsp;
				</div>
				<div className="col">
				<input type="radio" name="category_type" value={category_keys[3]} onChange={this.categoryChanged} />Test Results
				</div>
				</div>


				<AlertSite sites={this.props.sites}  valueLink={this.linkState('siteField')} />

				<AlertErrorCode valueLink={this.linkState('errorCodeField')} />

				<AlertAnomalieType anomalie_types={this.props.anomalie_types}  valueLink={this.linkState('anomalieField')} />


				<div className="row">
				<div className="col pe-2">
				&nbsp;
				</div>
				<div className="col">
				<input type="submit" value="Create Alert" className="btn-primary"/>
				</div>

				</div>

				</form>
				</div>
			);
		}
	});

