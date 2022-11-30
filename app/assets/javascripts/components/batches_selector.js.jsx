var BatchesSelector = React.createClass({
  getInitialState: function () {
    return {
      batches: this.props.batches,
    };
  },

  render: function () {
    return (<div className="batches-selector">
      {this.renderTitle()}
      {this.state.batches.map(this.renderBatch)}

      <a className="add-items" href="#" onClick={this.addBatch}>
        <div className="add-items">
          <div className="icon-circle-plus icon-blue icon-margin"></div>
          <div className="add-link">ADD BATCH</div>
        </div>
      </a>
    </div>);
  },

  renderTitle() {
    var batches = this.state.batches;
    if (!batches.length) return;

    var count = batches.reduce(function (a, e) {
      return e.value ? a + 1 : a;
    }, 0);

    return (<div className="batches-count">
      <div className="title">{count}&nbsp;{count == 1 ? "batch" : "batches"}</div>
    </div>);
  },

  renderBatch(batch, index) {
    if (batch.value && batch.label) {
      function removeBatch(event) {
        this.removeBatch(event, index);
      }
      return (<div className="list-items" key={"batches-selector-" + index}>
        <div className="items-row">
          <div className="items-left">
            <div className="items-row-actions">
              <input type="hidden" name={this.props.name + "[" + index + "]"} value={batch.value}/>
              <a href="#" onClick={removeBatch.bind(this)} title="Remove this batch">
                <i className="icon-delete hex-gray bigger"></i>
              </a>
            </div>
            <div className="items-item">{batch.value}</div>
          </div>
          <div className="items-concentration">{batch.label}</div>
        </div>
      </div>);
    } else {
      function selectBatch(_, options) {
        this.selectBatch(index, options && options[0]);
      }
      return (<div className="list-items" key={"batches-selector-" + index}>
        <div className="items-row">
          <CdxSelectAutocomplete
            className={this.props.className}
            url={this.props.url}
            placeholder={this.props.placeholder}
            value={batch.uuid}
            prepareOptions={this.prepareOptions}
            autoselect={true}
            onSelect={selectBatch.bind(this)}
          />
        </div>
      </div>);
    }
  },

  prepareOptions: function (options) {
    return options.map(function (option) {
      return option;
    });
  },

  addBatch: function (event) {
    event.preventDefault();
    var batches = this.state.batches;
    batches.push({ value: "", label: "" });
    this.setState({ batches: batches });
  },

  selectBatch: function (index, batch) {
    var batches = this.state.batches;
    batches[index] = batch;
    this.setState({ batches: batches });
  },

  removeBatch: function (event, index) {
    event.preventDefault();

    var batches = this.state.batches;
    batches.splice(index, 1);

    this.setState({ batches: batches });
  },
});
