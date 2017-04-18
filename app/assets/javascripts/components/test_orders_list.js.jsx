var TestOrderRow = React.createClass({
  render: function() {
    var test_order = this.props.test_order;

    var assays = test_order.encounter.diagnosis;
    var fillAssays = this.props.assaysColspan - assays.length;

    return (
    <tr data-href={'/encounters/' + test_order.encounter.uuid}>
      <td>{test_order.encounter.uuid}</td>
      { this.props.showSites ? <td>{test_order.site ? test_order.site.name : null}</td> : null }

      {assays.map(function(assay) {
         return <td key={assay.condition} className="text-right"><AssayResult assay={assay}/></td>;
      })}
      { fillAssays > 0 ? <td colSpan={fillAssays}></td> : null }

      <td>{test_order.encounter.start_time}</td>
      <td>{test_order.encounter.end_time}</td>
    </tr>);
  }
});

var TestOrdersList = React.createClass({
  getDefaultProps: function() {
    return {
      title: "Test orders",
      titleClassName: "",
      downloadCsvPath: null,
      allowSorting: false,
      orderBy: "",
      showSites: true
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

    var totalAssaysColCount = _.reduce(this.props.testOrders, function(m, test_order) {
      return Math.max(m, test_order.encounter.diagnosis.length);
    }, 1);

    var timeWidth = this.props.showSites ? "15%" : "25%";

    return (
      <table className="table" cellPadding="0" cellSpacing="0">
        <colgroup>
          <col width="15%" />
          { this.props.showSites ? <col width="20%" /> : null }
          {_.range(totalAssaysColCount).map(function(i){
            return (<col key={i} width={(30 / totalAssaysColCount) + "%"} />);
          }.bind(this))}
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
            {sortableHeader("ID", "encounter.uuid")}
            { this.props.showSites ? <th>Site</th> : null }
            <th colSpan={totalAssaysColCount} className="text-right">Results</th>

            {sortableHeader("Start time", "encounter.start_time")}
            {sortableHeader("End time", "encounter.end_time")}
          </tr>
        </thead>
        <tbody>
          {this.props.testOrders.map(function(test_order) {
             return <TestOrderRow key={test_order.encounter.uuid} test_order={test_order}
              showSites={this.props.showSites} showDevices={this.props.showDevices}
              assaysColspan={totalAssaysColCount} />;
          }.bind(this))}
        </tbody>
      </table>
    );
  }
});

var TestOrdersIndexTable = React.createClass({
  render: function() {
    return <TestOrdersList testOrders={this.props.tests}  aaa={this.props.all_test_orders}
              downloadCsvPath={this.props.downloadCsvPath}
              title={this.props.title} titleClassName="table-title"
              allowSorting={true} orderBy={this.props.orderBy}
              showSites={this.props.showSites} showDevices={this.props.showDevices} />
  }
});
