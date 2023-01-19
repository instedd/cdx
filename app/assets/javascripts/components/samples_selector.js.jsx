var SamplesSelector = React.createClass({
  getInitialState: function () {
    return {
      samples: this.props.samples,
    };
  },
  reset : function() {
    this.setState({ samples: [] });
  },
  render: function () {
    let clearButton = <a className="clear-samples" href="#" onClick={this.reset}></a>;
    
    return (<div className="samples-selector">
      {clearButton}
      {this.renderTitle()}
      {this.state.samples.map(this.renderSample)}

      <a className="add-items" href="#" onClick={this.addSample}>
        <div className="add-items">
          <div className="icon-circle-plus icon-blue icon-margin"></div>
          <div className="add-link">ADD SAMPLE</div>
        </div>
      </a>
    </div>);
  },

  renderTitle() {
    var samples = this.state.samples;
    if (!samples.length) return;

    var count = samples.reduce(function (a, e) {
      return e.uuid ? a + 1 : a;
    }, 0);

    return (<div className="items-count">
      <div className="title">{count}&nbsp;{count == 1 ? "sample" : "samples"}</div>
    </div>);
  },

  renderSample(sample, index) {
    if (sample.uuid) {
      function removeSample(event) {
        this.removeSample(event, index);
      }
      return (<div className="list-items" key={"samples-selector-" + index}>
        <div className="items-row">
          <div className="items-left">
            <div className="items-row-actions">
              <input type="hidden" name={this.props.name + "[" + index + "]"} value={sample.uuid}/>
              <a href="#" onClick={removeSample.bind(this)} title="Remove this sample">
                <i className="icon-delete icon-gray bigger"></i>
              </a>
            </div>
            <div className="items-item">{sample.uuid} <span>{sample.batch_number}</span></div>
          </div>
          <div className="items-concentration">{sample.concentration} copies/ml</div>
        </div>
      </div>);
    } else {
      function selectSample(_, options) {
        this.selectSample(index, options && options[0]);
      }
      return (<div className="list-items" key={"samples-selector-" + index}>
        <div className="items-row">
          <CdxSelectAutocomplete
            className={this.props.className}
            url={this.props.url}
            placeholder={this.props.placeholder}
            value={sample.uuid}
            prepareOptions={this.prepareOptions}
            autoselect={true}
            onSelect={selectSample.bind(this)}
          />
        </div>
      </div>);
    }
  },

  prepareOptions: function (options) {
    return options.map(function (option) {
      option.value = option.uuid;
      option.label = option.uuid + " (" + option.batch_number + ")";
      return option;
    });
  },

  addSample: function (event) {
    event.preventDefault();

    var samples = this.state.samples;
    samples.push({ uuid: "" });
    this.setState({ samples: samples });
  },

  selectSample: function (index, sample) {
    var samples = this.state.samples;
    samples[index] = sample;
    this.setState({ samples: samples });
  },

  removeSample: function (event, index) {
    event.preventDefault();

    var samples = this.state.samples;
    samples.splice(index, 1);

    this.setState({ samples: samples });
  },
});
