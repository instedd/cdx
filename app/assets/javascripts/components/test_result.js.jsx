// TODO should not show institution if user has only one
var AddItemSearchTestResultTemplate = React.createClass({
  render: function() {
    return (<span>{this.props.item.test_id} - {this.props.item.name} ({this.props.item.device.name})</span>);
  }
});

var TestResult = React.createClass({
  render: function() {
    test = this.props.test_result
    return (
    <li>
     {test.name} ({test.device.name})
    </li>);
  }
});

var TestResultsList = React.createClass({
  render: function() {
    return (
      <ul>
        {this.props.testResults.map(function(test_result) {
           return <TestResult key={test_result.uuid} test_result={test_result}/>;
        })}
      </ul>
    );
  }
});
