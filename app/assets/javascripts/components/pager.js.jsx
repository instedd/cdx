var Pager = React.createClass({
  getInitialState: function() {
    return {
      page: this.props.initialPage,
    };
  },

  _setPage: function(page) {
    this.setState(React.addons.update(this.state, {
      page: { $set: page },
    }), function() {
      this.fireShowPageDebounced();
    });
  },

  handlePageChange: function(event) {
    this._setPage(event.target.value);
  },

  componentWillMount: function() {
    this.fireShowPageDebounced = _.debounce(function(){
      this.fireShowPage.apply(this);
    }, 500);
  },

  fireShowPage: function() {
    var pageNumber = parseInt(this.state.page) || 1;
    pageNumber = Math.max(Math.min(pageNumber, this.props.totalPages), 1)
    this.props.showPage(pageNumber);
  },

  prevPage: function(event) {
    this._setPage(parseInt(this.state.page) - 1);
    event.preventDefault();
  },

  nextPage: function(event) {
    this._setPage(parseInt(this.state.page) + 1);
    event.preventDefault();
  },

  render: function() {
    return (
      <div className="pagination">
        <a className="btn-link" href="#" onClick={this.prevPage} disabled={this.state.page == 1 ? "disabled" : ""}>&lt;</a>
        <a className="btn-link" href="#" onClick={this.nextPage} disabled={this.state.page == this.props.totalPages ? "disabled" : ""}>&gt;</a>
        <input className="input-x-small text-right" type="text" value={this.state.page} onChange={this.handlePageChange}/>
        <span>
          of {this.props.totalPages}
        </span>
      </div>
    );
  }
});
