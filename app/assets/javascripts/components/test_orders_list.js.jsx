var TestOrderRow = React.createClass({
  render: function() {
    test_order = this.props.test_order

    return (
    <tr data-href={'/encounters/' + test_order.encounter.uuid}>
      <td>{test_order.encounter.uuid}</td>
      { this.props.showSites ? <td>{test_order.site ? test_order.site.name : null}</td> : null }
      <td><AssaysResult assays={test_order.encounter.diagnosis} /></td>
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

    var timeWidth = this.props.showSites ? "15%" : "25%";

    return (
      <table className="table" cellPadding="0" cellSpacing="0">
        <colgroup>
          <col width="15%" />
          { this.props.showSites ? <col width="20%" /> : null }
          <col width="30%" />
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
            <th>Diagnosis</th>
            {sortableHeader("Start time", "encounter.start_time")}
            {sortableHeader("End time", "encounter.end_time")}
          </tr>
        </thead>
        <tbody>
          {this.props.testOrders.map(function(test_order) {
             return <TestOrderRow key={test_order.uuid} test_order={test_order}
              showSites={this.props.showSites} showDevices={this.props.showDevices}/>;
          }.bind(this))}
        </tbody>
      </table>
    );
  }
});

var TestOrdersIndexTable = React.createClass({
  render: function() {
    return <TestOrdersList testOrders={this.props.tests}
              downloadCsvPath={this.props.downloadCsvPath}
              title={this.props.title} titleClassName="table-title"
              allowSorting={true} orderBy={this.props.orderBy}
              showSites={this.props.showSites} showDevices={this.props.showDevices} />
  }
});
