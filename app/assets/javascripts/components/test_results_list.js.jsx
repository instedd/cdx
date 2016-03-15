var TestResultRow = React.createClass({
  render: function() {
    var test = this.props.test_result;

    var assays = splitAssays(test.assays);
    var fillQualitative = this.props.qualitativeColspan - assays.qualitative.length;
    var fillQuantitative = this.props.quantitativeColspan - assays.quantitative.length;

    return (
    <tr data-href={'/test_results/' + test.uuid}>
      <td>{test.name}</td>

      {assays.qualitative.map(function(assay) {
         return <td key={assay.condition}><AssayResult assay={assay}/></td>;
      })}
      { fillQualitative > 0 ? <td colSpan={fillQualitative}></td> : null }

      {assays.quantitative.map(function(assay) {
         return <td key={assay.condition}><AssayQuantitativeResult assay={assay}/></td>;
      })}
      { fillQuantitative > 0 ? <td colSpan={fillQuantitative}></td> : null }

      { this.props.showSites ? <td>{test.site ? test.site.name : null}</td> : null }
      { this.props.showDevices ? <td>{test.device ? test.device.name : null}</td> : null }
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
      orderBy: "",
      showSites: true,
      showDevices: true
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

    var qualitativeCount = 1, quantitativeCount = 1;
    for(var i = 0; i < this.props.testResults.length; i++) {
      var assays = splitAssays(this.props.testResults[i].assays);
      qualitativeCount = Math.max(qualitativeCount, assays.qualitative.length);
      quantitativeCount = Math.max(quantitativeCount, assays.quantitative.length);
    }
    var totalAssaysColCount = qualitativeCount + quantitativeCount;

    var timeWidth;
    if (this.props.showSites && this.props.showDevices) {
      timeWidth = "15%";
    } else if (this.props.showSites || this.props.showDevices) {
      timeWidth = "20%";
    } else {
      timeWidth = "25%";
    }

    return (
      <table className="table" cellPadding="0" cellSpacing="0">
        <colgroup>
          <col width="15%" />
          {_.range(totalAssaysColCount).map(function(i){
            return (<col key={i} width={(34 / totalAssaysColCount) + "%"} />);
          }.bind(this))}
          { this.props.showSites ? <col width="7%" /> : null }
          { this.props.showDevices ? <col width="7%" /> : null }
          <col width="7%" />
          <col width={timeWidth} />
          <col width={timeWidth} />
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
            <th colSpan={qualitativeCount}>Qualitative</th>
            <th colSpan={quantitativeCount}>Quantitative</th>
            { this.props.showSites ? <th>Site</th> : null }
            { this.props.showDevices ? <th>Device</th> : null }
            {sortableHeader("Sample ID", "sample.id")}
            {sortableHeader("Start time", "test.start_time")}
            {sortableHeader("End time", "test.end_time")}
          </tr>
        </thead>
        <tbody>
          {this.props.testResults.map(function(test_result) {
             return <TestResultRow key={test_result.uuid} test_result={test_result}
              showSites={this.props.showSites} showDevices={this.props.showDevices}
              qualitativeColspan={qualitativeCount} quantitativeColspan={quantitativeCount} />;
          }.bind(this))}
        </tbody>
      </table>
    );
  }
});

var TestResultsIndexTable = React.createClass({
  render: function() {
    return <TestResultsList testResults={this.props.tests}
              downloadCsvPath={this.props.downloadCsvPath}
              title={this.props.title} titleClassName="table-title"
              allowSorting={true} orderBy={this.props.orderBy}
              showSites={this.props.showSites} showDevices={this.props.showDevices} />
  }
});
