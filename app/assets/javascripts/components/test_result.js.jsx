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
      allowSorting: false,
      orderBy: ""
      // TODO add showDevice, showSite toggle
    }
  },

  render: function() {
    var sortableHeader = function (title, field) {
      if (this.props.allowSorting) {
        return <SortableColumnHeader title={title} field={field} orderBy={this.props.orderBy} />
      } else {
        return <th>{title}</th>;
      }
    }.bind(this);

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
            {sortableHeader("Name", "test.name")}
            <th>Result</th>
            <th>Site</th>
            <th>Device</th>
            {sortableHeader("Sample ID", "sample.id")}
            {sortableHeader("Start time", "test.start_time")}
            {sortableHeader("End time", "test.end_time")}
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

var SortableColumnHeader = React.createClass({
  render: function() {
    var field = this.props.field;
    var descField = "-" + field;
    var orderByThis = false;
    var orderByThisDir = null;
    var appendTitle = null;

    var nextOrder = field;

    if (this.props.orderBy == field) {
      orderByThis = true;
      orderByThisDir = 'asc';
      nextOrder = descField;
      appendTitle = " ↑";
    } else if (this.props.orderBy == descField) {
      orderByThis = true;
      orderByThisDir = 'desc';
      appendTitle = " ↓";
    }

    var sortUrl = URI(window.location.href).setSearch({"order_by": nextOrder});

    return (<th>
        <a href={sortUrl} className={classNames({ordered: orderByThis, ["ordered-" + orderByThisDir]: orderByThis})}>{this.props.title} {appendTitle}</a>
      </th>);
  },
});

var TestResultsIndexTable = React.createClass({
  render: function() {
    return <TestResultsList testResults={this.props.tests}
              downloadCsvPath={this.props.downloadCsvPath}
              title={this.props.title} titleClassName="table-title"
              allowSorting={true} orderBy={this.props.orderBy}/>
  }
});
