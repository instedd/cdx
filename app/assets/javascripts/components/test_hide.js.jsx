
var TestHide = React.createClass({
  render: function() {
    return (
	     <div className="row" id="xxx">
	      <div className="col pe-2">
	        Test hide
	      </div>
	    <div className="col">
		   <input type="text" placeholder="YYYYour name" ref="author" />
	    <input type="text" placeholder="SSSay something..." ref="comment" />
	      </div>
	</div>
    );
  }
});



var AlertDescription = React.createClass({
  render: function() {
    return (
	     <div className="row">
	      <div className="col pe-2">
	        Description
	      </div>
	    <div className="col">
		   <input type="text" placeholder="description" ref="alert=description" />
	      </div>
	</div>
    );
  }
});


var AlertErrorCode = React.createClass({
  render: function() {
    return (
	     <div className="row" id="errorcoderow">
	      <div className="col pe-2">
	        Errors
	      </div>
	    <div className="col">
		   <input type="text" placeholder="All error codes will be reported" valueLink={this.props.valueLink} />
	      </div>
	</div>
    );
  }
});




// http://voidcanvas.com/react-tutorial-two-way-data-binding/
var AlertSite = React.createClass({	
		getDefaultProps: function(){
					return {
						multiple: true,
						name: 'selectSite',
					}
				},					
	                  //https://github.com/JedWatson/react-select/issues/256				
					  onChange(textValue, arrayValue) {					  
					      // Multi select: grab values and send array of values to valueLink
					     this.props.valueLink.requestChange(_.pluck(arrayValue, 'value').join());
					  },
  render: function() {
	var siteOptions=[];
    for (var i = 0; i < this.props.sites.length; i++) {
		siteOption={};
	    siteOption["value"] = this.props.sites[i].id;
	    siteOption["label"] = this.props.sites[i].name;
	    siteOptions.push(siteOption);
	}
	
	var { valueLink, value, onChange, ...other } = this.props;
    return (
	     <div className="row">
	      <div className="col pe-2">
	        &nbsp;
	      </div>
	    <div className="col">
		<Select
			    name="site"
			    value={value || valueLink.value}
			    options={siteOptions}			   
			    multi="true"			    
			    onChange={this.onChange}
			/>
	      </div>
	</div>
    );
  }
});





// http://voidcanvas.com/react-tutorial-two-way-data-binding/
var AlertAnomalieType = React.createClass({	
		getDefaultProps: function(){
					return {
						multiple: false,
						name: 'Anomalie',
					}
				},					
	                  //https://github.com/JedWatson/react-select/issues/256				
					  onChange(textValue, arrayValue) {					  
					     this.props.valueLink.requestChange(textValue);
					  },
  render: function() {
	var options=[];
    for (var i = 0; i < Object.keys(this.props.anomalie_types).length; i++) {
		option={};
	    option["value"] = i;
	    option["label"] = Object.keys(this.props.anomalie_types)[i];
	    options.push(option);
	}
	
	var { valueLink, value, onChange, ...other } = this.props;
    return (
	     <div className="row" id="anomalierow">
	      <div className="col pe-2">
	        Anomalies;
	      </div>
	    <div className="col">
		<Select
			    name="anomalie"
			    value={value || valueLink.value}
			    options={options}			   
			    multi="false"			    
			    onChange={this.onChange}
			/>
	      </div>
	</div>
    );
  }
});
