var ClientSideSortableColumnHeader = React.createClass({
	getInitialState: function() {
		var field = this.props.field;
		var descField = "-" + field;
		var orderByThisDirection = null;
		var appendTitle = null;

		// Note: put a '-' in front of field name to sort asc
		if (this.props.orderBy == field) {
			orderByThisDirection = 'asc';
			appendTitle = " ↑";
			this.props.setAppendTitle(field,appendTitle, orderByThisDirection);
		} else if (this.props.orderBy == descField) {
			orderByThisDirection = 'desc';
			appendTitle = " ↓";
			this.props.setAppendTitle(field,appendTitle, orderByThisDirection);
		}

		return {
			appendTitle: appendTitle,
			orderByThisDirection: orderByThisDirection
		};
	},
	headerReorder: function(header) {
		direction=this.props.appendTitleDirection[header];
		if (direction == 'desc') {
			direction='asc';
			appendTitle = " ↑";
		} else {
			direction='desc';
			appendTitle = " ↓";
		}

		var sortHeader=header;
		if (direction=='desc') {
			sortHeader = '-'+header;
		}

		var new_data = this.props.data;
		new_data.sort(this.dynamicSort(sortHeader));
		this.props.reorderData(new_data);
		this.props.setAppendTitle(header,appendTitle,direction);
	},
	dynamicSort: function(property) {
		var sortOrder = 1;
		if(property[0] === "-") {
			sortOrder = -1;
			property = property.substr(1);
		}
		return function (a,b) {
			var result = (a[property] < b[property]) ? -1 : (a[property] > b[property]) ? 1 : 0;
			return result * sortOrder;
		}
	},
	render: function() {
		var field = this.props.field;
		return (<th>
			<a onClick={this.headerReorder.bind(this, this.props.field)} className={classNames({ordered: this.props.appendTitleSelected[this.props.field], ["ordered-" + this.state.orderByThisDirection]: this.props.appendTitle[this.props.field] })}>{this.props.title} {this.props.appendTitle[this.props.field]}</a>
		</th>);
	},
});



var TestOrderRow = React.createClass({
	render: function() {
		var data = this.props.row_data;
		return (
			<tr key={this.props.index}>
				<td>{data['device']}</td>
				<td>{data['location']}</td>
				<td>{data['error_code']}</td>
				<td>{data['count']}</td>
				<td>{data['last_error']}</td>
			</tr>);
		}
	});



	var OutstandingTestsTable = React.createClass({
		getInitialState: function() {
			appendTitle=[{"device":""},
			{"location":""},
			{"error_code":""},
			{"count":""},
			{"last_error":""} ];

			appendTitleDirection=[{"device":""},
			{"location":""},
			{"error_code":""},
			{"count":""},
			{"last_error":""} ];

			appendTitleSelected=[{"device":true},
			{"location":false},
			{"error_code":false},
			{"count":false},
			{"last_error":false} ];
			return {
				data: this.props.data,
				appendTitle: appendTitle,
				appendTitleDirection: appendTitleDirection,
				appendTitleSelected: appendTitleSelected
			};
		},
		componentDidMount: function() {
			$('#device_code_table_chart').scrollTableBody({rowsToDisplay:7});
		},
		getDefaultProps: function() {
			return {
				title: "Tests",
				titleClassName: "",
				allowSorting: false,
				orderBy: ""
			}
		},
		setAppendTitleDirection : function(header,value, direction) {
			tempAppendTitle = this.state.appendTitle;
			tempAppendTitleDirection = this.state.appendTitleDirection;
			tempAppendTitleSelected = this.state.appendTitleSelected;

			for (var key in tempAppendTitle) {
				tempAppendTitle[key]="";
				appendTitleSelected[key]=false;
			}

			tempAppendTitle[header]=value;
			this.setState({appendTitle: tempAppendTitle});

			tempAppendTitleDirection[header]=direction;
			this.setState({appendTitleDirection: tempAppendTitleDirection});

			tempAppendTitleSelected[header]=true;
			this.setState({appendTitleSelected: tempAppendTitleSelected});

		},
		reorderData: function(new_data) {
			this.setState({data: new_data});
		},
		randomString: function(){
			return Math.random().toString(36);
		},

		render: function() {
			var sortableHeader = function (title, field) {
				if (this.props.allowSorting) {
					return <ClientSideSortableColumnHeader  appendTitleSelected={this.state.appendTitleSelected} appendTitle={this.state.appendTitle} appendTitleDirection={this.state.appendTitleDirection} setAppendTitle={this.setAppendTitleDirection} title={title} field={field} orderBy={"-device"} data={this.state.data}  reorderData={this.reorderData} />
				} else {
					return <th>{title}</th>;
					}
				}.bind(this);

				return (
					<table className="table" cellPadding="0" cellSpacing="0"  id="device_code_table_chart" >
						<colgroup>
							<col width="20%" />
							<col width="20%" />
							<col width="20%" />
							<col width="20%" />
							<col width="20%" />
						</colgroup>
						<thead>
							<tr>
								{sortableHeader("Device", "device")}
								{sortableHeader("Location", "location")}
								{sortableHeader("Error Code", "error_code")}
								{sortableHeader("Error Count", "count")}
								{sortableHeader("Last Error", "last_error")}
							</tr>

						</thead>
						<tbody key={this.randomString()}>
							{this.state.data.map(function(row_data,index) {
								return <TestOrderRow key={index} row_data={row_data} />;
							}.bind(this))}
						</tbody>
					</table>
				);
			}
		});
