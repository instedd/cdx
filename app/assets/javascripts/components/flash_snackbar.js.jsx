var FlashSnackbar = React.createClass({
  componentDidMount: function() {
    var flashn = $(".flash-snackbar");
    flashn.delay(3000).fadeOut(300);
      $(".close-notification").click(function(){
      flashn.hide();
    });
  },
  render: function() {
    return (
        <div className="flash flash-snackbar">
            <div className={"icon "+this.props.icon} />
            <div className="flash-snackbar-message" > 
                <span className="flash-snackbar-line1">{this.props.line1}</span> <br />
                <span className="flash-snackbar-line2">{this.props.line2}</span>
            </div>
            <a className='close-notification'>x</a>
        </div>
    )
  }
});

var SampleTransferSuccessSnackbar = React.createClass({
  render: function() {
    return (
      <FlashSnackbar 
        icon="icon-send" 
        line1="Samples transferred successfully"
        line2={String(this.props.samplesCount)+" sample"+(this.props.samplesCount===1?'':'s')+" transferred to "+this.props.institution}
      />
    )
  }
});
