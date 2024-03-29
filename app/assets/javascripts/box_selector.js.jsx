var BoxSelector = React.createClass({
  getInitialState: function() {
    return {
      includeQcInfo: this.props.includeQcInfo,
      boxes: this.props.boxes,
      search: "",
      error: null,
      status: "input",
    };
  },

  showQcWarningCheckbox: function(selectedBoxes) {
    const haveQc = selectedBoxes.filter((box) => box.hasQcReference === true).length
    const missingQuantity = selectedBoxes.length - haveQc
    return (
      <div>
        {haveQc > 0 && this.props.displayQcInfo && this.includeQcInfoCheckbox()}
        {missingQuantity > 0 && this.props.displayQcInfo && this.qcInfoMessage(missingQuantity, selectedBoxes)}
      </div>
    )
  },

  renderBoxes: function() {
    const selector = this;
    
    function renderBox(box, i) {
      function handleClick(e) {
        e.preventDefault();
        selector.removeBox(box);
      }

      function renderOnSamplesReports(box){
        let name = `samples_report[box_ids][]`;
        return <div>
          <div className="list-items">
            <div className="items-row-with-remove">
              <a href="#" className="selector-list-item__remove" title="Remove box" onClick={handleClick}>
                <i className="icon-circle-minus icon-gray" />
              </a>
              <div className="items-row" dangerouslySetInnerHTML={{ __html: box.preview }}></div>
            </div>
            <input type="hidden" name={name} value={box.id} />
          </div>
            { box.samplesWithoutResults ? 
              (<div className="muted"><div className="icon-info-outline icon-gray"/>Samples without results will be ignored</div>) :
              ("") }
        </div>
      }

      function renderOnTransferPackages(box,id){
        let name = `transfer_package[box_transfers_attributes][${id}][box_id]`;
        return <div className="selector-list-item">
          <div dangerouslySetInnerHTML={{ __html: box.preview }}></div>
          <input type="hidden" name={name} value={box.id} />
          <a href="#" className="selector-list-item__remove" title="Remove box" onClick={handleClick}>
            <i className="icon-close" />
          </a>
        </div>
      }

      let id = Math.floor(Math.random() * 1000000000);
      if (selector.props.caller == 'samples_reports'){
        return renderOnSamplesReports(box, id);
      }
      else if (selector.props.caller == 'transfer_packages') {
        return renderOnTransferPackages(box, id);
      }
      
    }

    const listItems = this.state.boxes.map(renderBox)
    return ({ listItems });
  },

  removeBox: function(box) {
    let boxes = this.state.boxes.filter((value) => value != box)
    this.setState({
      boxes: boxes
    });
  },

  qcInfoMessage: function(missingQuantity, selectedBoxes) {
    const infoMessage = (missingQuantity > 0 && missingQuantity != selectedBoxes.length)
      ? `There is no Quality Control (QC) info available for ${missingQuantity} ${missingQuantity === 1 ? 'box' : 'boxes'}`
      : "There is no Quality Control (QC) info available for these boxes"

    return (
      <div className="qc-info-message">
        <span className="icon-info-outline icon-gray" />
        <input type="hidden" name="includes_qc_info" value="false" />
        <div className="notification-text">{infoMessage}</div>
      </div>
    )
  },

  handleChange: function(e) {
    let search = e.target.value.trim();

    this.setState({ search: search });

    function isUUID(str) {
      const regexExp = /^[0-9a-fA-F]{8}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{4}\b-[0-9a-fA-F]{12}$/gi;

      return regexExp.test(str);
    }

    if (isUUID(search)) {
      this.loadBox(search)
    }
  },

  onKeyDown: function(e) {
    this.setState({
      error: null,
    })
    if (e.key == "Enter") {
      e.preventDefault();

      this.loadBox(this.state.search)
    }
  },

  loadBox: function(uuid) {
    url = "/"+this.props.caller+"/find_box"
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
        } else if (data.boxes.length == 1) {
          let box = data.boxes[0]
          if (box.error) {
            this.setState({
              error: box.error,
              state: "error"
            })
          } else if (this.addBox(box)) {
            this.setState({
              search: "",
              status: "input",
            })
          } else {
            this.setState({
              status: "input",
            })
          }
        } else if (data.boxes.length == 0) {
          this.setState({
            error: `No box found for ${uuid.length == 36 ? "UUID" : "UUID prefix"} ${uuid}`,
            status: "error",
          })
        } else {
          this.setState({
            error: `Multiple boxes found for ${uuid.length == 36 ? "UUID" : "UUID prefix"} ${uuid}`,
            status: "error",
          })
        }
      }.bind(this),
      error: function(xhr, status, err) {
        this.setState({
          error: "Error retrieving box data.",
          status: "error",
        })
      }.bind(this),
    });
  },

  addBox: function(box) {
    if (this.state.boxes.find((value) => value.uuid == box.uuid)) {
      // avoid duplicates
      this.setState({
        error: `Box ${box.uuid} is already selected.`
      })
      return false;
    }

    let boxes = this.state.boxes
    boxes.push(box)
    this.setState({ boxes: boxes })

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
            <div className="selector-list">
              {this.renderBoxes()}
            </div>
            {(this.props.maxBoxes ==-1 || this.state.boxes.length < this.props.maxBoxes) &&
            <input type="text" size="36" maxlength="36" placeholder="Enter, paste or scan box ID"
              value={this.state.search}
              onChange={this.handleChange} onKeyDown={this.onKeyDown}
              className={this.state.error ? "input-required" : ""} />
            }
            <div className="error">
              {this.renderError()}
            </div>
          </div>
        </div>
        <div className="row">
          <div className="col">
            {this.showQcWarningCheckbox(this.state.boxes)}
          </div>
        </div>
      </div>
    )
  },
});
