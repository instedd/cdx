var AddItemSearchTestResultTemplate = React.createClass({
  render: function() {
    return (<span>{this.props.item.test_id} - {this.props.item.name} ({this.props.item.device.name})</span>);
  }
});

var AssaysResult = React.createClass({
  // TODO allow assaysLayout so among different test results, the assays results are rendered in the same order and missing ones can be detected.
  render: function() {
    return (
      <span>
        {this.props.assays.map(function(assay) {
           return <AssayResult key={assay.condition} assay={assay}/>;
        })}
      </span>
    );
  }
});

var AssaysResultList = React.createClass({
  render: function() {
    return  (
      <div>
        {this.props.assays.map(function(assay, index) {
          return (
            <div className="row" key={index}>
              <div className="col pe-4">
                <div className="underline">
                  <span><b>{assay.name.toUpperCase()}</b></span>
                </div>
              </div>
              <div className="col pe-3">
                <b>{_.capitalize(assay.result)}</b>
              </div>
              <div className="col pe-1">
                {assay.quantitative}
              </div>

            </div>
          );
        })}
      </div>
    );
  }
});

var AssayResult = React.createClass({
  render: function() {
    var assay = this.props.assay;

    return (
      <span className={"assay-result assay-result-" + assay.result}>
        {assay.name.toUpperCase()}
      </span>);
  }
});

var TestResult = React.createClass({

  render: function() {
    test = this.props.test_result

    var siteName = null;
    if (test.site)
      siteName = test.site.name;

    return (
    <tr>
      <td>{test.name}</td>
      <td><AssaysResult assays={test.assays} /></td>
      <td>{test.sample_entity_id}</td>
      <td>{siteName}</td>
      <td>{test.start_time}</td>
    </tr>);
  }
});

var TestResultsList = React.createClass({
  render: function() {
    return (
      <table className="table">
        <thead>
          <tr>
            <th className="tableheader" colSpan="5">Tests</th>
          </tr>
          <tr>
            <th>Test name</th>
            <th>Result</th>
            <th>Sample ID</th>
            <th>Site</th>
            <th>Date</th>
          </tr>
        </thead>
        <tbody>
          {this.props.testResults.map(function(test_result) {
             return <TestResult key={test_result.uuid} test_result={test_result}/>;
          })}
        </tbody>
      </table>
    );
  }
});
