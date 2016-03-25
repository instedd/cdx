/*
var DeviceErrorTable11 = React.createClass({
	render: function() {
		
		rows11 = [{"id":1,"first_name":"William","last_name":"Elliott","email":"welliott0@wisc.edu",
		             "country":"Argentina","ip_address":"247.180.226.89"},
		              {"id":2,"first_name":"Carl","last_name":"Ross","email":"cross1@mlb.com",
		             "country":"South Africa","ip_address":"27.146.70.36"},
		              {"id":3,"first_name":"Jeremy","last_name":"Scott","email":"jscott2@cbsnews.com",
		             "country":"Colombia","ip_address":"103.52.74.225"}
		    ];

		
		data = [ ["device":"device1","location":"location1",
		                     {"error_code":"123","count":66,"last_error":"2016-02-05"},
		                     {"error_code":"227","count":56,"last_error":"2016-02-05"} ],
		
		          ["device":"device2","location":"location2",
		                     {"error_code":"155","count":86,"last_error":"2016-07-05"},
								         {"error_code":"500","count":6,"last_error":"2016-02-15"},
								         {"error_code":"700","count":55,"last_error":"2016-01-15"} ]
		    ];
		

	
				data = [ 
				         ["device":"device1","location":"location1","error_code":"123","count":66,"last_error":"2016-02-05"],
				          ["device":"device1","location":"location1","error_code":"443","count":6,"last_error":"2016-12-05"]
				         ],
				         [
 				           ["device":"device2","location":"location4","error_code":"123","count":7,"last_error":"2016-02-05"],
				           ["device":"device2","location":"location4","error_code":"643","count":8,"last_error":"2016-12-05"],
				           ["device":"device2","location":"location4","error_code":"743","count":11,"last_error":"2016-12-05"]
			           ]	
				    ];
					
					
			data = [ 
			         ["device":"device1","location":"location1","error_code":"123","count":66,"last_error":"2016-02-05"],
			          ["device":"device1","location":"location1","error_code":"443","count":6,"last_error":"2016-12-05"],
			           ["device":"device2","location":"location4","error_code":"123","count":7,"last_error":"2016-02-05"],
			           ["device":"device2","location":"location4","error_code":"643","count":8,"last_error":"2016-12-05"],
			           ["device":"device2","location":"location4","error_code":"743","count":11,"last_error":"2016-12-05"]
			    ];
			
				
    return (
	<div>
	<table>
	<tr>
   <th>Device</th>
   <th>Error Code</th>
<th>Error Count</th>
<th>Last Error</th>
 </tr>
	<tr><td>ddd</td></tr>
	</table>
</div>
    );
	}
});

*/


var ClientSideSortableColumnHeader = React.createClass({
/*
http://stackoverflow.com/questions/1129216/sort-array-of-objects-by-string-property-value-in-javascript
function dynamicSort(property) {
    var sortOrder = 1;
    if(property[0] === "-") {
        sortOrder = -1;
        property = property.substr(1);
    }
    return function (a,b) {
        var result = (a[property] < b[property]) ? -1 : (a[property] > b[property]) ? 1 : 0;
        return result * sortOrder;
    }
}
So you can have an array of objects like this:

var People = [
    {Name: "Name", Surname: "Surname"},
    {Name:"AAA", Surname:"ZZZ"},
    {Name: "Name", Surname: "AAA"}
];
...and it will work when you do:

People.sort(dynamicSort("Name"));
People.sort(dynamicSort("Surname"));
People.sort(dynamicSort("-Surname"));
*/
/*
	compare: function(a,b) {
	  if (a.count < b.count)
	    return -1;
	  else if (a.count > b.count)
	    return 1;
	  else 
	    return 0;
	},
	*/
  render: function() {
    var field = this.props.field;
    var descField = "-" + field;
    var orderByThis = false;
    var orderByThisDir = null;
    var appendTitle = null;

    var nextOrder = field;

    if (this.props.orderBy == field) {
      orderByThis = true;
      orderByThisDir = 'asc';
      nextOrder = descField;
      appendTitle = " ↑";
    } else if (this.props.orderBy == descField) {
      orderByThis = true;
      orderByThisDir = 'desc';
      appendTitle = " ↓";
    }

var new_data = this.props.data;
 new_data.sort(this.compare);
this.props.reorderData(new_data);

/*
return (
<div></div>
	);
*/

    var sortUrl = URI(window.location.href).setSearch({"order_by": nextOrder});

    return (<th>
        <a href={sortUrl} className={classNames({ordered: orderByThis, ["ordered-" + orderByThisDir]: orderByThis})}>{this.props.title} {appendTitle}</a>
      </th>);

  },
});




var DeviceRow = React.createClass({
  render: function() {
    var data = this.props.row_data;

    return (
    <tr>
      <td>{data['device.model']}</td>
      <td>{data['location']}</td>
      <td>{data['test.error_code']}</td>
      <td>{data['count']}</td>
      <td>{data['last_error']}</td>
    </tr>);
  }
});



var DeviceErrorTable = React.createClass({
				getInitialState: function() {
					var data = [ 
					         {"device":"device1","uuid":"1","location":"location1","test.error_code":"123","count":66,"last_error":"2016-02-05"},
					          {"device":"device1","uuid":"2","location":"location1","error_code":"443","count":6,"last_error":"2016-12-05"},					         
					           {"device":"device2","uuid":"3","location":"location4","error_code":"123","count":7,"last_error":"2016-02-05"},
					           {"device":"device2","uuid":"4","location":"location4","error_code":"643","count":8,"last_error":"2016-12-05"},
					           {"device":"device2","uuid":"5","location":"location4","error_code":"743","count":11,"last_error":"2016-12-05"},
										 {"device":"device1","uuid":"6","location":"location1","error_code":"123","count":66,"last_error":"2016-02-05"},
						          {"device":"device1","uuid":"7","location":"location1","error_code":"443","count":6,"last_error":"2016-12-05"},					         
						           {"device":"device2","uuid":"8","location":"location4","error_code":"123","count":7,"last_error":"2016-02-05"},
						           {"device":"device2","uuid":"9","location":"location4","error_code":"643","count":8,"last_error":"2016-12-05"},
						           {"device":"device2","uuid":"10","location":"location4","error_code":"743","count":11,"last_error":"2016-12-05"},
											 {"device":"device1","uuid":"11","location":"location1","error_code":"123","count":66,"last_error":"2016-02-05"},
							          {"device":"device1","uuid":"12","location":"location1","error_code":"443","count":6,"last_error":"2016-12-05"},					         
							           {"device":"device2","uuid":"13","location":"location4","error_code":"123","count":7,"last_error":"2016-02-05"},
							           {"device":"device2","uuid":"14","location":"location4","error_code":"643","count":8,"last_error":"2016-12-05"},
							           {"device":"device2","uuid":"15","location":"location4","error_code":"743","count":11,"last_error":"2016-12-05"},
												 {"device":"device1","uuid":"16","location":"location1","error_code":"123","count":66,"last_error":"2016-02-05"},
								          {"device":"device1","uuid":"17","location":"location1","error_code":"443","count":6,"last_error":"2016-12-05"},					         
								           {"device":"device2","uuid":"18","location":"location4","error_code":"123","count":7,"last_error":"2016-02-05"},
								           {"device":"device2","uuid":"19","location":"location4","error_code":"643","count":8,"last_error":"2016-12-05"},
								           {"device":"device2","uuid":"20","location":"location4","error_code":"743","count":11,"last_error":"2016-12-05"},			
													 {"device":"device1","uuid":"21","location":"location1","error_code":"123","count":66,"last_error":"2016-02-05"},
									          {"device":"device1","uuid":"22","location":"location1","error_code":"443","count":6,"last_error":"2016-12-05"},					         
									           {"device":"device2","uuid":"23","location":"location4","error_code":"123","count":7,"last_error":"2016-02-05"},
									           {"device":"device2","uuid":"24","location":"location4","error_code":"643","count":8,"last_error":"2016-12-05"},
									           {"device":"device2","uuid":"25","location":"location4","error_code":"743","count":11,"last_error":"2016-12-05"}
					    ];

					return {
						data: this.props.data
					};
				},
				componentDidMount: function() {
			      $('#arrestedDevelopment').scrollTableBody({rowsToDisplay:7});
			  },
  getDefaultProps: function() {
    return {
      title: "Tests",
      titleClassName: "",
      downloadCsvPath: null,
      allowSorting: false,
      orderBy: "",
      showSites: true,
      showDevices: true
    }
  },
reorderData: function(new_data) {
	//this.setState({data: new_data});
},
  render: function() {
    var sortableHeader = function (title, field) {
      if (this.props.allowSorting) {
        return <ClientSideSortableColumnHeader title={title} field={field} orderBy={"device.model"} data={this.state.data}  reorderData={this.reorderData} />
      } else {
        return <th>{title}</th>;
      }
    }.bind(this);

    return (
      <table className="table" cellPadding="0" cellSpacing="0"  id="arrestedDevelopment" >
        <colgroup>
          <col width="20%" />
<col width="20%" />
 <col width="20%" />
 <col width="20%" />
 <col width="20%" />
        </colgroup>
        <thead>					
					 <tr>
	            {sortableHeader("Device", "data.device.model")}
	              {sortableHeader("Location", "location")}
	            {sortableHeader("Error Code", "test.error_code")}
	            {sortableHeader("Error Count", "count")}
	            {sortableHeader("Last Error", "data.last_error")}
	          </tr>
	
        </thead>
        <tbody>
          {this.state.data.map(function(row_data,index) {
             return <DeviceRow key={index} row_data={row_data} />;
          }.bind(this))}
        </tbody>
      </table>
    );
  }
});


