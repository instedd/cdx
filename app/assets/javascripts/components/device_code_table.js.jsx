var DeviceRow = React.createClass({
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


	var DeviceErrorTable = React.createClass({
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
			
			if (this.props.data.length==0) {
				shouldHide=true;
			} else {
				shouldHide=false;
			}
			
			return {
				data: this.props.data,
				appendTitle: appendTitle,
				appendTitleDirection: appendTitleDirection,
				appendTitleSelected: appendTitleSelected,
				shouldHide: shouldHide
			};
		},
		getDefaultProps: function() {
			return {
				title: "Tests",
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
					<div>
						<div className={this.state.shouldHide ? '' : 'hidden'}>
						<span className="horizontal-bar-value">There is no data to display</span>
						</div>
					  <div className={this.state.shouldHide ? 'hidden' : ''}>
						<table className="table" cellPadding="0" cellSpacing="0"  id="device_code_table_chart"  >
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
						</table>
						<div className="table_scroll_container">
							<table className="table scroll" cellPadding="0" cellSpacing="0" >
								<colgroup>
									<col width="20%" />
									<col width="20%" />
									<col width="20%" />
									<col width="20%" />
									<col width="20%" />
								</colgroup>
								<tbody key={this.randomString()} >
									{this.state.data.map(function(row_data,index) {
										return <DeviceRow key={index} row_data={row_data} />;
									}.bind(this))}
								</tbody>
							</table>
						</div>
			     </div>
					</div>
				);
			}
		});
