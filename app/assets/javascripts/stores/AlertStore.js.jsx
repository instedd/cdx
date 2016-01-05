//var Reflux = require('reflux');
//var AlertActions = require('../actions/AlertActions');

var _notes = []; //This is private notes array

//  http://www.sitepoint.com/creating-note-taking-app-react-flux/


var AlertStore = Reflux.createStore({
 // listenables: [Actions],

  init: function() {
    // Here we listen to actions and register callbacks
    this.listenTo(AlertActions.createAlert, this.onCreate);
    this.listenTo(AlertActions.editAlert, this.onEdit);
  },
  onCreate: function(url,alert) {
 //   _notes.push(note); //create a new note

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


    // Trigger an event once done so that our components can update. Also pass the modified list of notes.
  //  this.trigger(_notes); 
  }
/*
,
  onEdit: function(note) {
    // Update the particular note item with new text.
    for (var i = 0; i < _notes.length; i++) {
      if(_notes[i]._id === note._id) {
        _notes[i].text = note.text;
        this.trigger(_notes);
        break;
      }
    }
  },

  //getter for notes
  getNotes: function() {
    return _notes;
  },

  //getter for finding a single note by id
  getNote: function(id) {
    for (var i = 0; i < _notes.length; i++) {
      if(_notes[i]._id === id) {
        return _notes[i];
      }
    }
  }
*/
});

//module.exports = AlertStore; //Finally, export the Store