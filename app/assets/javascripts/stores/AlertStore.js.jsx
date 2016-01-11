	//  http://www.sitepoint.com/creating-note-taking-app-react-flux/

var AlertStore = Reflux.createStore({
 //TODO listenables: [Actions],

 init: function() {
    // Here we listen to actions and register callbacks
    this.listenTo(AlertActions.createAlert, this.onCreate);
    this.listenTo(AlertActions.editAlert, this.onEdit);
    this.listenTo(AlertActions.getDevices, this.getDevices);
  },
  onCreate: function(url,alert_info, successUrl, errorCallback) {
   $.ajax({
    url: url,
    dataType: 'json',
    type: 'POST',
    data: {"alert" : alert_info},
    success: function(data) {
			//   this.loadCommentsFromServer();
	//		if (data.status == 'error') {
	//			alert(data.message); //TODO show errors nicely
	//		} else {
		//	window.location.href = '/alerts/'
			window.location.href = successUrl;
	//	   }
		}.bind(this),
		error: function(xhr, status, err) {
			// console.error(url, status, err.toString());
		//	alert("Alert save error " + err.toString() ); //TODO show errors nicely
	//	errorCallback(err.toString() );
		
		errorCallback(xhr.responseText);
	//	errorCallback.call(xhr.responseText);
		
		}.bind(this)
	});
 },
 onEdit: function(note) {
 }
/*
,
getDevices: function(url,sites) {
   $.ajax({
    url: url,
    dataType: 'json',
    type: 'GET',
    success: function(data) {
			//   this.loadCommentsFromServer();
			console.log("aHHHHHHH");
		}.bind(this),
		error: function(xhr, status, err) {
			console.error(url, status, err.toString());
		}.bind(this)
	});
 },
*/
});

