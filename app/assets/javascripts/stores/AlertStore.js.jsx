//  http://www.sitepoint.com/creating-note-taking-app-react-flux/

var AlertStore = Reflux.createStore({
 //TODO listenables: [Actions],

 init: function() {
    // Here we listen to actions and register callbacks
    this.listenTo(AlertActions.createAlert, this.onCreate);
    this.listenTo(AlertActions.editAlert, this.onEdit);
  },
  onCreate: function(url,alert) {

   $.ajax({
    url: url,
    dataType: 'json',
    type: 'POST',
    data: {"alert" : alert},
    success: function(data) {
			//   this.loadCommentsFromServer();
		}.bind(this),
		error: function(xhr, status, err) {
			console.error(url, status, err.toString());
		}.bind(this)
	});


 }

 ,
 onEdit: function(note) {
 },

});

