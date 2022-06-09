var SamplesSelector = React.createClass({
  getInitialState: function () {
    return {
      samples: this.props.samples,
    };
  },

  render: function () {
    return (<div className="samples-selector">
      {this.renderTitle()}
      {this.state.samples.map(this.renderSample.bind(this))}

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
    var self = this;

    if (sample.uuid) {
      return (<div className="batches-samples">
        <div className="samples-row">
          <div className="samples-item">{sample.uuid}</div>
          <div className="samples-row-actions">
            <input type="hidden" name={self.props.name + "[" + index + "]"} value={sample.uuid}/>
            <span>{sample.batch_number}</span>
            <a href="#" onClick={function (event) { self.removeSample(event, index) }} title="Remove this sample">
              <i className="icon-close icon-gray bigger"></i>
            </a>
          </div>
        </div>
      </div>);
    } else {
      return (<div className="batches-samples">
        <div className="samples-row">
          <CdxSelectAutocomplete
            key={"samples-selector-" + index}
            className={self.props.className}
            url={self.props.url}
            placeholder={self.props.placeholder}
            value={sample.uuid}
            onSelect={function (_, options) { self.selectSample(index, options && options[0]) }}
          />
        </div>
      </div>);
    }
  },

  addSample: function (event) {
    event.preventDefault();

    var samples = this.state.samples;
    samples.push({ uuid: "" });
    this.setState({ samples: samples });
  },

  selectSample(index, sample) {
    var samples = this.state.samples;
    samples[index] = sample;
    this.setState({ samples: samples });
  },

  removeSample(event, index) {
    event.preventDefault();

    var samples = this.state.samples;
    samples.splice(index, 1);

    this.setState({ samples: samples });
  }
});
