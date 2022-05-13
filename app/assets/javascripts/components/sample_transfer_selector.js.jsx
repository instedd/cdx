var SampleTransferSelector = React.createClass({
  getInitialState: function() {
    return {
      includeQcInfo: this.props.includeQcInfo,
      samples: this.props.samples,
      search: "",
      error: null,
      status: "input",
    };
  },

  showQcWarningCheckbox: function(selectedSamples) {
    const haveQc = selectedSamples.filter((sample) => sample.hasQcReference === true).length
    const missingQuantity = selectedSamples.length - haveQc
    return (
      <div>
        {haveQc > 0 && this.includeQcInfoCheckbox()}
        {missingQuantity > 0 && this.qcInfoMessage(missingQuantity, selectedSamples)}
      </div>
    )
  },

  renderSamples: function() {
    const selector = this;

    function renderSample(sample, i) {
      function handleClick(e) {
        e.preventDefault();
        selector.removeSample(sample);
      }

      let id = Math.floor(Math.random() * 1000000000);
      let name = `transfer_package[sample_transfers_attributes][${id}][sample_id]`;
      return <div className="sample-transfer-preview">
        <div dangerouslySetInnerHTML={{ __html: sample.preview }}></div>
        <input type="hidden" name={name} value={sample.id} />
        <a href="#" className="sample-transfer-preview__remove" title="Remove sample" onClick={handleClick}>
          <i className="icon-close" />
        </a>
      </div>
    }

    const listItems = this.state.samples.map(renderSample)
    return ({ listItems });
  },

  removeSample: function(sample) {
    let samples = this.state.samples.filter((value) => value != sample)
    this.setState({
      samples: samples
    });
  },

  qcInfoMessage: function(missingQuantity, selectedSamples) {
    const infoMessage = (missingQuantity > 0 && missingQuantity != selectedSamples.length)
      ? `There is no Quality Control (QC) info available for ${missingQuantity} ${missingQuantity === 1 ? 'sample' : 'samples'}`
      : "There is no Quality Control (QC) info available for these samples"

    return (
      <div className="icon-info-outline icon-gray qc-info-message">
        <input type="hidden" name="includes_qc_info" value="false" />
        <div className="notification-text">{infoMessage}</div>
      </div>
    )
  },

  handleChange: function(e) {
    let search = e.target.value;

    this.setState({ search: search });

    function isUUID(str) {
      const regexExp = /^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$/gi;

      return regexExp.test(str);
    }

    if (isUUID(search)) {
      this.loadSample(search)
    }
  },

  onKeyDown: function(e) {
    this.setState({
      error: null,
    })
    if (e.key == "Enter") {
      e.preventDefault();

      this.loadSample(this.state.search)
    }
  },

  loadSample: function(uuid) {
    url = "/transfer_packages/find_sample"
    this.setState({
      error: null,
      status: "loading",
    });
    $.ajax({
      url: url,
      dataType: 'json',
      type: 'GET',
      data: { context: this.props.context, uuid: uuid },
      success: function(data) {
        if (data.error) {
          this.setState({
            error: data.error,
            status: "input",
          })
        } else if (data.samples.length == 1) {
          let sample = data.samples[0]
          if (sample.error) {
            this.setState({
              error: sample.error,
              state: "error"
            })
          } else if (this.addSample(sample)) {
            this.setState({
              search: "",
              status: "input",
            })
          } else {
            this.setState({
              status: "input",
            })
          }
        } else if (data.samples.length == 0) {
          this.setState({
            error: `No sample found for ${uuid.length == 36 ? "UUID" : "UUID prefix"} ${uuid}`,
            status: "error",
          })
        } else {
          this.setState({
            error: `Multiple samples found for ${uuid.length == 36 ? "UUID" : "UUID prefix"} ${uuid}`,
            status: "error",
          })
        }
      }.bind(this),
      error: function(xhr, status, err) {
        this.setState({
          error: xhr.responseText,
          status: "error",
        })
      }
    });
  },

  addSample: function(sample) {
    if (this.state.samples.find((value) => value.uuid == sample.uuid)) {
      // avoid duplicates
      this.setState({
        error: `Sample ${sample.uuid} is already selected.`
      })
      return false;
    }

    let samples = this.state.samples
    samples.push(sample)
    this.setState({ samples: samples })

    return true
  },

  includeQcInfoCheckbox: function() {
    toggleQcInfo = function() {
      this.setState({
        includeQcInfo: !this.state.includeQcInfo
      });
    }.bind(this)

    return (
      <div className="qc-info-checkbox">
        <input name="transfer_package[includes_qc_info]" id="include-qc-check" type="checkbox" checked={this.state.includeQcInfo} onChange={toggleQcInfo} />
        <label htmlFor="include-qc-check">Include a copy of the QC data</label>
      </div>
    )
  },

  renderError: function() {
    let error = this.state.error;
    return (
      { error }
    )
  },

  render: function() {
    return (
      <div>
        <div className="row">
          <div className="col">
            <div className="sample-transfer-list">
              {this.renderSamples()}
            </div>
            <input type="text" size="36" maxlength="36" placeholder="Enter, paste or scan sample ID"
              value={this.state.search}
              onChange={this.handleChange} onKeyDown={this.onKeyDown}
              className={this.state.error ? "input-required" : ""} />

            <div className="error">
              {this.renderError()}
            </div>
          </div>
        </div>
        <div className="row">
          <div className="col">
            {this.showQcWarningCheckbox(this.state.samples)}
          </div>
        </div>
      </div>
    )
  },
});
