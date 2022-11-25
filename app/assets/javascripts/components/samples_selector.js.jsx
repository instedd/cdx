var SamplesSelector = React.createClass({
  getInitialState: function () {
    return {
      samples: this.props.samples,
    };
  },

  render: function () {
    return (<div className="samples-selector">
      {this.renderTitle()}
      {this.state.samples.map(this.renderSample)}

      <a className="add-samples" href="#" onClick={this.addSample}>
        <div className="add-samples">
          <div className="icon-circle-plus icon-blue icon-margin"></div>
          <div className="add-sample-link">ADD SAMPLE</div>
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

    return (<div className="samples-count">
      <div className="title">{count}&nbsp;{count == 1 ? "sample" : "samples"}</div>
    </div>);
  },

  renderSample(sample, index) {
    if (sample.uuid) {
      function removeSample(event) {
        this.removeSample(event, index);
      }
      return (<div className="batches-samples" key={"samples-selector-" + index}>
        <div className="samples-row">
          <div className="samples-left">
            <div className="samples-row-actions">
              <input type="hidden" name={this.props.name + "[" + index + "]"} value={sample.uuid}/>
              <span>{sample.batch_number}</span>
              <a href="#" onClick={removeSample.bind(this)} title="Remove this sample">
                <i className="icon-delete hex-gray bigger"></i>
              </a>
            </div>
            <div className="samples-item">{sample.uuid}</div>
          </div>
          <div className="samples-concentration">{sample.concentration} copies/ml</div>
        </div>
      </div>);
    } else {
      function selectSample(_, options) {
        this.selectSample(index, options && options[0]);
      }
      return (<div className="batches-samples" key={"samples-selector-" + index}>
        <div className="samples-row">
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
