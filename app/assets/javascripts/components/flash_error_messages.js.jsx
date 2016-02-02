// http://stackoverflow.com/questions/26964974/handle-rails-flash-messages-after-ajax-calls-using-reactjs
var FlashErrorMessages = React.createClass({
  getInitialState: function() {
    return {messages: this.props.messages};
  },

  render: function() {
    return (
	    <div id="#flash_messages" >
      <div className="flash_messages_component">
        {this.props.messages.map(function(message, index) {
          _reason = message[0];
          _text  = message[1];
          return (
            <div key={index} className="flash-error-reactjs">
             {_reason} : {_text}
            </div>
          );
        }.bind(this))}
      </div>
      </div>
    )
  }

});