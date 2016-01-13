	//  http://www.sitepoint.com/creating-note-taking-app-react-flux/

var AlertStore = Reflux.createStore({
 //TODO listenables: [Actions],

 init: function() {
    // Here we listen to actions and register callbacks
    this.listenTo(AlertActions.createAlert, this.onCreate);
    this.listenTo(AlertActions.updateAlert, this.onUpdate);
  },
  onCreate: function(url,alert_info, successUrl, errorCallback) {
   $.ajax({
    url: url,
    dataType: 'json',
    type: 'POST',
    data: {"alert" : alert_info},
    success: function(data) {
			window.location.href = successUrl;
		}.bind(this),
		error: function(xhr, status, err) {
		errorCallback(xhr.responseText);
		}.bind(this)
	});
 },
  onUpdate: function(url,alert_info, successUrl, errorCallback) {
   $.ajax({
    url: url,
    dataType: 'json',
    type: 'PUT',
    data: {"alert" : alert_info},
    success: function(data) {
			window.location.href = successUrl;
		}.bind(this),
		error: function(xhr, status, err) {
		errorCallback(xhr.responseText);
		}.bind(this)
	});
 },
});

