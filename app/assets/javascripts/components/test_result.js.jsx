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
                  <span><b>{(assay.name || assay.condition).toUpperCase()}</b></span>
                </div>
              </div>
              <div className="col pe-3">
                <b>{_.capitalize(assay.result)}</b>
              </div>
              <div className="col pe-1">
                {assay.quantitative_result}
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
        {(assay.name || assay.condition).toUpperCase()}
      </span>);
  }
});

var TestResult = React.createClass({

  render: function() {
    test = this.props.test_result

    return (
    <tr data-href={'/test_results/' + test.uuid}>
      <td>{test.name}</td>
      <td><AssaysResult assays={test.assays} /></td>
      <td>{test.site ? test.site.name : null}</td>
      <td>{test.device ? test.device.name : null}</td>
      <td>{test.sample_entity_ids}</td>
      <td>{test.start_time}</td>
      <td>{test.end_time}</td>
    </tr>);
  }
});

var TestResultsList = React.createClass({
  getDefaultProps: function() {
    return {
      title: "Tests",
      titleClassName: "",
      downloadCsvPath: null,
      // TODO add showDevice, showSite toggle
    }
  },

  render: function() {
    return (
      <table className="table" cellPadding="0" cellSpacing="0">
        <colgroup>
          <col width="20%" />
          <col width="20%" />
          <col width="10%" />
          <col width="10%" />
          <col width="10%" />
          <col width="15%" />
          <col width="15%" />
        </colgroup>
        <thead>
          <tr>
            <th className="tableheader" colSpan="7">
              <span className={this.props.titleClassName}>{this.props.title}</span>

              { this.props.downloadCsvPath ? (
                <span className="table-actions">
                  <a href={this.props.downloadCsvPath} title="Download CSV">
                    <span className="icon-download icon-gray" />
                  </a>
                </span>) : null }
            </th>
          </tr>
          <tr>
            <th>Name</th>
            <th>Result</th>
            <th>Site</th>
            <th>Device</th>
            <th>Sample ID</th>
            <th>Start time</th>
            <th>End time</th>
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

var TestResultsIndexTable = React.createClass({
  render: function() {
    return <TestResultsList testResults={this.props.tests} title={this.props.title} downloadCsvPath={this.props.downloadCsvPath} titleClassName="table-title" />
  }
});
