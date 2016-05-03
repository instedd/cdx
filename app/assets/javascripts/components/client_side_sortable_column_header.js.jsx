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
