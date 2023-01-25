var BatchesSelector = React.createClass({
  getInitialState: function () {
    return {
      batches: this.props.batches,
      samples: this.props.samples,
      concentration: this.props.concentration,
      replicate: this.props.replicate,
      distractor: this.props.distractor,
      instruction: this.props.instruction,
      list: [],
    };
  },
  reset: function() {
    this.setState({
      batches: [],
      samples: this.props.samples,
      concentration: null,
      replicate: null,
      distractor: null,
      instruction: null,
      list: [],
    });
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
      <a className="clear-batches" href="#" onClick={this.reset}></a>
      <div className="items-count">
        <div className="title">{this.state.list.length}&nbsp;{this.state.list.length == 1 ? "batch" : "batches"}</div>
      </div>
      {this.state.list ? this.state.list.map(this.renderList) : false}
      {this.state.batches.map(this.renderBatch)}

      {button}
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
              <i className="icon-delete icon-gray bigger"></i>
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
              <i className="icon-delete icon-gray bigger"></i>
            </a>
          </div>
          <div>
            <span className="subtitle">Batch</span>
            <div className="items-item">{batch.label}</div>
            <div>
              <input type="checkbox" id="distractor" name="distractor" value={this.state.distractor} onChange={this.changeDistractor}/>
              <label htmlFor="distractor">Distractor</label>
              <p className="distractor-description">When enabled, the system will consider that the sample test result should be negative regardless of its concentration and threshold</p>
            </div>

            <div>
              <label htmlFor="batch-instructions">Instructions</label>
            </div>
            <input type="text" id="batch-instructions" name="instructions" value={this.state.instruction} onChange={this.changeInstruction} className="full-input" />
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
                  <button className="icon-blue icon-check" onClick={addConcentration.bind(this)}></button>
                </div>
              </div>
            </div>
            <span className="warn hidden" id="unconfirmed-copies-warning">
              To add the batch, you must confirm the replicates & concentrations above by pressing the blue check. If you don't want to add them, please erase the fields.
            </span>
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

    var concentrationItem = `${count} in ${unique.length} different concentration${unique.length>1?"s":""}`;

    return (<div className="list-items" key={"list-selector-" + index}>
      <div className="items-row">
        <div className="items-left">
          <div className="items-row-actions">
            <a href="#" onClick={removeList.bind(this)} title="Remove this batch">
              <i className="icon-delete icon-gray bigger"></i>
            </a>
          </div>
          <div className="items-item">{batch.label}</div>
        </div>
        <div className="items-concentration">{concentrationItem}</div>
        <input type="hidden" name={"box[batch_uuids][" + index + "]"} value={batch.value}/>
        {batch.samples ? batch.samples.map((sample, concentration_index) =>
            <span>
              <input type="hidden" name={"box[concentrations][" + index + "][" + concentration_index + "][concentration]"} value={sample.concentration} />
              <input type="hidden" name={"box[concentrations][" + index + "][" + concentration_index + "][replicate]"} value={sample.replicate} />
              <input type="hidden" name={"box[concentrations][" + index + "][" + concentration_index + "][distractor]"} value={sample.distractor} />
              <input type="hidden" name={"box[concentrations][" + index + "][" + concentration_index + "][instruction]"} value={sample.instruction} />
            </span>
          ) : false}
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

    if (parseInt(this.state.replicate) >0 || parseInt(this.state.concentration) >0 ){
      document.getElementById("unconfirmed-copies-warning").classList.remove("hidden");
      return 
    }
    var list = this.state.list;
    var batches = this.state.batches;
    batches[0].samples = batches[0].samples.map( (sample) => {
      return { replicate: sample.replicate, concentration: sample.concentration, distractor: this.state.distractor, instruction: this.state.instruction }
    })
    list.push(batches)
    this.setState({ list: list });
    this.setState({ batches: [] });
    this.setState({distractor: null });
    this.setState({instruction: null });
  },
  addConcentration: function (event) {
    event.preventDefault();
    document.getElementById("unconfirmed-copies-warning").classList.add("hidden");
    if (parseInt(this.state.replicate) >0 && parseInt(this.state.concentration) >0 ){
      this.state.batches[0].samples.push({ replicate: this.state.replicate, concentration: this.state.concentration });
      this.setState({concentration: null });
      this.setState({replicate: null });
    }
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
  },
  changeDistractor: function( event ) {
    this.setState({distractor: event.target.value});
  },
  changeInstruction: function( event ) {
    this.setState({instruction: event.target.value});
  }
});
