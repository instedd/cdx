var BatchesSelector = React.createClass({
  getInitialState: function () {
    return {
      batches: this.props.batches,
      concentrations: this.props.concentrations,
      list: this.props.list,
    };
  },

  render: function () {
    return (<div className="batches-selector">
      {this.renderTitle()}
      {this.state.list ? this.state.list.map(this.renderList) : false}
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

    return (<div className="items-count">
      <div className="title">{count}&nbsp;{count == 1 ? "batch" : "batches"}</div>
    </div>);
  },

  renderConcentration(concentration, index) {
    console.log('renderConcentration', concentration, index);
    function removeConcentration(event) {
      this.removeConcentration(event, index);
    }
    return (<div className="list-items" key={"concentrations-selector-" + index}>
      <div className="items-row">
        <div className="items-left">
          <div className="items-row-actions">
            <input type="hidden" name={this.props.name + "[" + index + "]"} value={concentration.replicate}/>
            <input type="hidden" name={this.props.name + "[" + index + "]"} value={concentration.concentration}/>
            <a href="#" onClick={removeConcentration.bind(this)} title="Remove this concentration">
              <i className="icon-delete hex-gray bigger"></i>
            </a>
          </div>
          <div className="items-item">{concentration.replicate}</div>
        </div>
        <div className="items-concentration">{concentration.concentration} copies/ml</div>
      </div>
    </div>);
  },

  renderBatch(batch, index) {
    console.log('renderBatch', batch, index);

    if (batch.value && batch.label) {
      function removeBatch(event) {
        this.removeBatch(event, index);
      }
      function addList(_, options) {
        this.addList(index, options && options[0]);
      }
      function addConcentration(_, options) {
        this.addConcentration(index, options && options[0]);
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
            <div className="items-item">{batch.value}</div>
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

              {this.state.concentrations ? this.state.concentrations.map(this.renderConcentration) : false}

            <div className="list-items">
              <div className="items-row">
                <div className="items-left">
                  <div className="items-row-actions">&nbsp;</div>
                  <div className="items-item"><input type="text" name="Replicates" value={this.state.Replicates} /> replicates</div>
                </div>
                <div className="items-concentration">
                  <input type="text" name="Concentration" value={this.state.Concentration} /> copies/ml
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
    console.log('renderList', batch, index);
    function removeList(event) {
      this.removeList(event, index);
    }
    return (<div className="list-items" key={"list-selector-" + index}>
      <div className="items-row">
        <div className="items-left">
          <div className="items-row-actions">
            /* here comes the input hidden values */
            <a href="#" onClick={removeList.bind(this)} title="Remove this batch">
              <i className="icon-delete hex-gray bigger"></i>
            </a>
          </div>
          <div className="items-item">{batch.uuid} <span>{batch.batch_number}</span></div>
        </div>
        <div className="items-concentration">{batch.concentration} copies/ml</div>
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
  addList: function (index, batch) {
    var batches = this.state.list;
    batches[index] = batch;
    batches[index].push({concentrations: this.state.concentrations })
    this.setState({ list: batches });
  },
  addConcentration: function (index, concentration) {
    console.log('addConcentration', concentration, index);
    var concentrations = this.state.concentrations;
    concentrations[index] = concentration;
    this.setState({ concentrations: concentrations });
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
  removeConcentration: function (event, index) {
    event.preventDefault();

    // var samples = this.state.batches.samples;
    // samples.splice(index, 1);
    //
    // this.setState({ samples: batches });
  },
});
