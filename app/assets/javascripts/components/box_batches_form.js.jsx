var BoxBatchesForm = React.createClass({
  getInitialState: function () {
    var batches = this.props.batches || [];

    batches.forEach(function (batch) {
      batch.key = cdxGenRandomKey(batches);
    });

    return {
      batches: batches,
      showBatchSelector: batches.length == 0,
    };
  },

  reset: function () {
    this.setState({
      batches: [],
      showBatchSelector: true,
    });
  },

  render: function () {
    var batches = this.state.batches;
    var removeBatch = this.removeBatch
    var onChange = this.onChange

    return (
      <div className="batches-selector" data-isvalid={this.isValid()}>
        <a className="clear-batches" href="#" onClick={this.reset} style={{ display: "none" }}></a>
        <div className="items-count">
          <div className="title">{batches.length}&nbsp;{batches.length == 1 ? "batch" : "batches"}</div>
        </div>
        {batches.map(function (batch) {
          return <BoxBatchForm
            key={"box_batches_" + batch.key}
            batch={batch}
            onChange={onChange}
            onRemove={removeBatch}
          />
        })}
        {this.state.showBatchSelector ? this.renderBatchSelector() : this.renderAddBatchButton() }
      </div>
    );
  },

  renderBatchSelector: function () {
    return (
      <div className="list-items">
        <div className="items-row">
          <CdxSelectAutocomplete
            className="input-block"
            url={this.props.findBatchUrl}
            name="box[batch_uuids]"
            placeholder="Enter batch id"
            value=""
            prepareOptions={this.prepareOptions}
            autoselect={true}
            onSelect={this.selectBatch}
            autoselect={true}
          />
        </div>
      </div>
    );
  },

  renderAddBatchButton: function () {
    return (
      <a className="add-items" href="#" onClick={this.showBatchSelector}>
        <div className="add-items">
          <div className="icon-circle-plus icon-blue icon-margin"></div>
          <div className="add-link">ADD BATCH</div>
        </div>
      </a>
    );
  },

  showBatchSelector: function (event) {
    event.preventDefault();
    this.setState({ showBatchSelector: true });
  },

  selectBatch: function (_, options) {
    if (options.length == 0) return;

    var batches = this.state.batches;

    options.forEach(function (option) {
      batches.push({
        key: cdxGenRandomKey(batches),
        uuid: option.value,
        batch_number: option.label,
        instruction: "",
        distractor: false,
        concentrations: [{}],
      });
    });

    this.setState({
      batches: batches,
      showBatchSelector: false,
    });
  },

  removeBatch: function (key) {
    var batches = this.state.batches;
    var index = batches.findIndex(function (batch) { return batch.key == key; });
    if (index >= 0) batches.splice(index, 1);
    this.setState({ batches: batches });
  },

  prepareOptions: function (options) {
    return options.map(function (option) {
      return option;
    });
  },

  onChange: function () {
    this.setState({});
  },

  isValid() {
    var batches = this.state.batches;
    return batches.length > 0 &&
      batches.reduce(function (a, e) { return a && e.isValid }, true);
  },
});

var BoxBatchForm = React.createClass({
  getInitialState: function () {
    var state = {
      batch: this.props.batch,
    };
    state.batch.concentrations.forEach(function (item) {
      if (!item.key) {
        item.key = cdxGenRandomKey([]);
      }
    });
    state.showForm = !this.isValid(state);
    return state;
  },

  render: function () {
    return (
      <div>
        { this.renderSummary() }
        { this.renderForm() }
      </div>
    );
  },

  renderSummary: function () {
    var concentrations = this.state.batch.concentrations;
    var total = concentrations.reduce(function (a, e) { return a + (parseInt(e.replicate, 10) || 0); }, 0);
    var unique = concentrations.reduce(function (a, e) { return e.concentration ? a.add(e.concentration) : a; }, new Set());
    var count = Array.from(unique).length;

    return (
      <div className={"list-items " + (this.state.showForm ? "nodisplay" : "") + " box-batch-summary"}>
        <div className="items-row">
          <div className="items-left">
            <div className="items-row-actions">
              <a href="#" onClick={this.onRemove} title="Remove this batch">
                <i className="icon-delete icon-gray bigger"></i>
              </a>
            </div>
            <div className="items-item">{this.props.batch.batch_number}&nbsp;{this.state.batch.distractor && "(distractor)"}</div>
          </div>
          <div className="items-concentration">{ `${total} in ${count} different concentration${count > 1 ? "s" : ""}`}</div>
          <div>
            &nbsp;
            <a href="#" onClick={this.showForm}>
              <div className="icon-keyboard-arrow-down icon-gray icon-margin bigger"></div>
            </a>
          </div>
        </div>
      </div>
    );
  },

  renderForm: function () {
    var self = this;
    var batch = this.props.batch;
    var renderConcentrationForm = this.renderConcentrationForm;

    function setDistractor() {
      batch.distractor = event.target.checked;
      self.setState({ batch: batch });
    }
    function setInstruction() {
      batch.instruction = event.target.value;
      self.setState({ batch: batch });
    }

    return (
      <div className={"list-items " + (this.state.showForm ? "" : "nodisplay") + " box-batch-form"}>
        <input type="hidden" name={this.fieldFor("batch_uuid")} value={batch.uuid}/>

        <div className="items-cols">
          <div className="items-row-actions">
            <a href="#" onClick={this.onRemove} title="Remove this batch">
              <i className="icon-delete icon-gray bigger"></i>
            </a>
          </div>

          <div>
            <span className="subtitle">Batch</span>
            <div className="items-item">{batch.batch_number}</div>
            <div>
              <input type="checkbox" id={this.idFor("distractor")} name={this.fieldFor("distractor")} checked={this.state.batch.distractor} value="1" onChange={setDistractor}/>
              <label htmlFor={this.idFor("distractor")}>Distractor</label>
              <p className="distractor-description">
                When enabled, the system will consider that the sample test result
                should be negative regardless of its concentration and threshold.
              </p>
            </div>

            <div><label htmlFor={this.idFor("instruction")}>Instructions</label></div>
            <input type="text" id={this.idFor("instruction")} name={this.fieldFor("instruction")} value={this.state.batch.instruction} onChange={setInstruction} className="full-input" />
          </div>

          <div>
            <span className="subtitle">Accomplished Concentrations</span>
            <div className="list-items box-batch-form-concentrations">
              {this.state.batch.concentrations.map(function (item) {
                return renderConcentrationForm(item)
              })}
            </div>

            <a href="#" className="add-items" onClick={this.addConcentration}>
              <div className="icon-circle-plus icon-blue icon-margin"></div>
              <div className="add-link">ADD CONCENTRATION</div>
            </a>
          </div>
        </div>

        <div className="col">
          <button className="btn-primary" onClick={this.hideForm} disabled={!this.isValid()}>OK</button>
          {/*<button className="btn-link" onClick={this.onCancel}>Cancel</button>*/}
        </div>
      </div>
    );
  },

  renderConcentrationForm: function (item) {
    var self = this;

    function set(key) {
      return function (event) {
        item[key] = event.target.value;

        if (self.props.onChange) {
          self.state.batch.isValid = self.isValid();
          self.props.onChange();
        }
        self.setState({});
      };
    }
    return (
      <div className="items-row" key={this.idFor("concentration", item.key)}>
        <div className="items-left">
          <div className="items-row-actions">
            <a href="#" onClick={this.removeConcentration} title="Remove this concentration" data-key={item.key}>
              <i className="icon-delete icon-gray bigger"></i>
            </a>
          </div>
          <div className="items-item">
            <input type="text" name={this.fieldFor("concentrations", item.key, "replicate")} value={item.replicate} onChange={set("replicate")}/>
            replicates
          </div>
        </div>
        <div className="items-concentration">
          <input type="text" name={this.fieldFor("concentrations", item.key , "concentration")} value={item.concentration} onChange={set("concentration")}/>
          copies/ml
        </div>
      </div>
    );
  },

  fieldFor: function () {
    var name = "box[batches][" + this.props.batch.key + "]";
    Array
      .from(arguments)
      .forEach(function (attr) { name += "[" + attr + "]"; });
    return name;
  },

  idFor: function () {
    var id = "box_batches_" + this.props.batch.key + "_";
    Array
      .from(arguments)
      .forEach(function (attr) { id += "_" + attr; });
    return id;
  },

  isValid: function (state) {
    var isValidConcentration = this.isValidConcentration;
    var batch = (state || this.state).batch;

    return batch.concentrations.reduce(function (a, e) {
      return a && isValidConcentration(e);
    }, true);
  },

  isValidConcentration: function (c) {
    return (parseInt(c.replicate, 10) > 0 && parseFloat(c.concentration, 10) >= 0);
  },

  hideForm: function (event) {
    event.preventDefault();
    this.setState({ showForm: false });
  },

  showForm: function (event) {
    event.preventDefault();
    this.setState({ showForm: true });
  },

  addConcentration: function (event) {
    event.preventDefault();

    var batch = this.state.batch;
    batch.concentrations.push({ key: cdxGenRandomKey(batch.concentrations) });
    this.setState({ batch: batch });
  },

  removeConcentration: function (event) {
    event.preventDefault();

    var key = event.currentTarget.dataset.key;
    var batch = this.state.batch;
    var concentrations = batch.concentrations;

    var index = concentrations.findIndex(function (item) { return item.key == key; });
    if (index >= 0) concentrations.splice(index, 1);

    if (concentrations.length < 1) {
      concentrations.push({ key: cdxGenRandomKey([]), });
    }
    this.setState({ batch: batch });
  },

  onRemove: function (event) {
    event.preventDefault();
    if (this.props.onRemove) {
      this.props.onRemove(this.props.batch.key);
    }
  },

  // onCancel: function (event) {
  //   event.preventDefault();

  //   if (this.props.onCancel) {
  //     this.props.onCancel(this.props.batch.key);
  //   }
  // }
});
