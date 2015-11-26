var TestResultsTable = React.createClass({
  getInitialState: function() {
    return {
      tests: [],
      totalCount: 0,

      offset: 0,
      pageSize: 10,
    };
  },

  componentDidMount: function() {
    this._fetchTests();
  },

  _fetchTests: function() {
    var options = _.extend({offset: this.state.offset, page_size: this.state.pageSize}, this.props.filter);
    $.get('/api/tests', options, function(result) {
      if (!this.isMounted()) return;

      this.setState(React.addons.update(this.state, {
        tests: { $set: result.tests },
        totalCount: { $set: result.total_count }
      }));

    }.bind(this));
  },

  gotoPage: function(page) {
    var targetOffset = (page - 1) * this.state.pageSize;
    if (this.state.offset != targetOffset) {
      this.setState(React.addons.update(this.state, {
        offset: { $set: targetOffset },
      }), function() {
        this._fetchTests();
      }.bind(this));
    }
  },

  pageSizes: function() {
    return (this.props.pageSizes || [2, 10, 50]).map(function(value) {
      return {label: value + " results per row", value: value};
    });
  },

  onPageSizeChange: function(targetPageSize) {
    if (this.state.pageSize != targetPageSize) {
      this.setState(React.addons.update(this.state, {
        pageSize: { $set: targetPageSize },
        offset: { $set: 0 }
      }), function() {
        this.refs.pager._setPage(1);
        this._fetchTests();
      }.bind(this));
    }
  },

  render: function() {
    return (
      <div>
        <table className="table row-href" cellPadding="0" cellSpacing="0">
          <thead>
            <tr>
              <th className="tableheader" colSpan="100">{this.state.totalCount} Tests</th>
            </tr>
            <tr>
              <th>Test</th>
              <th>Result</th>
              <th>Sample Id</th>
              <th>Start Time</th>
              <th>End Time</th>
            </tr>
          </thead>
          <tbody>
            {this.state.tests.map(function(test) {
              return (
                <tr key={test.test.uuid}>
                  <td>{test.test.name}</td>
                  <td><AssaysResult assays={test.test.assays} /></td>
                  <td>{test.sample.id}</td>
                  <td>{test.test.start_time}</td>
                  <td>{test.test.end_time}</td>
                </tr>
              );
            })}
          </tbody>
        </table>

        <div className="table-controls">
          <Pager
            ref="pager"
            initialPage={Math.floor(this.state.offset / this.state.pageSize) + 1}
            totalPages={Math.ceil(this.state.totalCount / this.state.pageSize)}
            showPage={this.gotoPage} />

          <CdxSelect items={this.pageSizes()} value={this.state.pageSize} onChange={this.onPageSizeChange} />
        </div>
      </div>
    );
  }
});
