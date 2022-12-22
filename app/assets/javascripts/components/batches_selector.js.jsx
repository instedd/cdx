var BatchesSelector = React.createClass({
  getInitialState: function () {
    return {
      batches: this.props.batches,
      samples: this.props.samples,
      concentration: this.props.concentration,
      replicate: this.props.replicate,
      list: [],
    };
  },

  render: function () {
    let button;
    if (this.state.batches.length > 0) {
      button = '';
    } else {
      button = <a className="add-items" href="#" onClick={this.addBatch}>
        <div className="add-items">
          <div className="icon-circle-plus icon-blue icon-margin"></div>
          <div className="add-link">ADD BATCH</div>
        </div>
      </a>;
    }

    return (<div className="batches-selector">
      {this.renderTitle()}
      {this.state.list ? this.state.list.map(this.renderList) : false}
      {this.state.batches.map(this.renderBatch)}

      {button}
    </div>);
  },

  renderTitle() {
    var batches = this.state.list;
    if (!batches.length) return;

    var count = batches.reduce(function (a, e) {
      return e.value ? a + 1 : a;
    }, 0);

    return (<div className="items-count">
      <div className="title">{count}&nbsp;{count == 1 ? "batch" : "batches"}</div>
    </div>);
  },

  renderConcentration(concentration, index) {
    function removeSample(event) {
      this.removeSample(event, index);
    }
    return (<div className="list-items" key={"concentrations-selector-" + index}>
      <div className="items-row">
        <div className="items-left">
          <div className="items-row-actions">
            <input type="hidden" name={this.props.name + "[" + index + "]"} value={concentration.replicate}/>
            <input type="hidden" name={this.props.name + "[" + index + "]"} value={concentration.concentration}/>
            <a href="#" onClick={removeSample.bind(this)} title="Remove this concentration">
              <i className="icon-delete hex-gray bigger"></i>
            </a>
          </div>
          <div className="items-item">{concentration.replicate}&nbsp; replicate{concentration.replicate > 1 ? 's' : ''}</div>
        </div>
        <div className="items-concentration">{concentration.concentration}&nbsp; copies/ml</div>
      </div>
    </div>);
  },

  renderBatch(batch, index) {
    if (batch.value && batch.label) {
      function removeBatch(event) {
        this.removeBatch(event, index);
      }
      function addList(event) {
        this.addList(event);
      }
      function addConcentration(event) {
        this.addConcentration(event);
      }
      return (<div className="list-items" key={"batches-selector-" + index}>
        <div className="items-cols">
          <div className="items-row-actions">
            <input type="hidden" name={this.props.name + "[" + index + "]"} value={batch.value}/>
            <a href="#" onClick={removeBatch.bind(this)} title="Remove this batch">
              <i className="icon-delete hex-gray bigger"></i>
            </a>
          </div>
          <div>
            <span className="subtitle">Batch</span>
            <div className="items-item">{batch.label}</div>
            <div>
              <input type="checkbox" id="distractor" name="distractor" value="{batch.distractor}"/>
              <label htmlFor="distractor">Distractor</label>
              <p className="distractor-description">When enabled, the system will consider that the sample test result should be negative regardless of its concentration and threshold</p>
            </div>

            <div>
              <span className="subtitle">Instructions</span>
            </div>
            <input type="text" name="instructions" className="full-input" />
          </div>
          <div>
            <span className="subtitle">Accomplished Concentrations</span>

              {batch.samples.map(this.renderConcentration)}

            <div className="list-items">
              <div className="items-row">
                <div className="items-left">
                  <div className="items-row-actions">&nbsp;</div>
                  <div className="items-item"><input type="text" name="Replicates" value={this.state.replicate} onChange={this.changeReplicate} /> replicates</div>
                </div>
                <div className="items-concentration">
                  <input type="text" name="Concentration" value={this.state.concentration} onChange={this.changeConcentration} /> copies/ml
                  <button className="hex-blue icon-check" onClick={addConcentration.bind(this)}></button>
                </div>
              </div>
            </div>
          </div>
        </div>
        <div className="col">
          <button className="btn-primary" onClick={addList.bind(this)}>Add</button>
          <button className="btn-link" onClick={removeBatch.bind(this)}>Cancel</button>
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

  renderList(batch, index) {
    batch = batch[0];
    var different = [];
    var count = 0;
    batch.samples.reduce(function (a, e) {
      different.push(e.concentration);
      count += parseInt(e.replicate);
    }, 0);
    let unique = [...new Set(different)];

    function removeList(event) {
      this.removeList(event, index);
    }
    return (<div className="list-items" key={"list-selector-" + index}>
      <div className="items-row">
        <div className="items-left">
          <div className="items-row-actions">
            <a href="#" onClick={removeList.bind(this)} title="Remove this batch">
              <i className="icon-delete hex-gray bigger"></i>
            </a>
          </div>
          <div className="items-item">{batch.label}</div>
        </div>
        <div className="items-concentration">{count} in {unique.length} different concentrations</div>
      </div>
    </div>);
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
  addList: function (event) {
    event.preventDefault();
    var list = this.state.list;
    var batches = this.state.batches;
    list.push(batches)
    this.setState({ list: list });
    this.setState({ batches: [] });
  },
  addConcentration: function (event) {
    event.preventDefault();
    this.state.batches[0].samples.push({ replicate: this.state.replicate, concentration: this.state.concentration});
    this.setState({concentration: null });
    this.setState({replicate: null });
  },

  removeBatch: function (event, index) {
    event.preventDefault();

    var batches = this.state.batches;
    batches.splice(index, 1);

    this.setState({ batches: batches });
  },
  removeList: function (event, index) {
    event.preventDefault();

    var batches = this.state.list;
    batches.splice(index, 1);

    this.setState({ list: batches });
  },
  removeSample: function (event, index) {
    event.preventDefault();

    var samples = this.state.batches[0].samples;
    samples.splice(index, 1);
    this.setState({ samples: samples });
  },

  changeConcentration: function( event ) {
    this.setState({concentration: event.target.value});
  },
  changeReplicate: function( event ) {
    this.setState({replicate: event.target.value});
  }
});
