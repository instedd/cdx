var UploadCsvBox = React.createClass({
  getInitialState: function() {
    return {
      csrfToken: this.props.csrf_token,
      url: this.props.validate_url,
      fieldName: this.props.name, // Initial fieldName value
      uploadRows: [], // Array to store upload rows
      hideListItems: "hidden",
      hideErrorMessage: "hidden",
      errorMessage:'',
      fileValue: ''
    };
  },

  handleChange: function(event) {
    this.setState({ fileValue: event.target.value });
    const file = event.target.files[0];
    const formData = new FormData();
    formData.append('csv_box', file);

    fetch(this.state.url, {
      method: "POST",
      headers: {
        "X-CSRF-Token": this.state.csrfToken
      },
      body: formData
    })
      .then(response => {
        if (response.ok) {
          return response.json();
        } else {
          throw new Error("Request failed. Status: " + response.status);
        }
      })
      .then(responseJson => {
        // Create row from template with filename and upload info
        const uploadInfo = {
          uploadedSamplesCount: responseJson.samples_count,
          notFoundUuids: responseJson.not_found_batches,
          errorMessage: responseJson.error_message,
        };

        // Add the new row to the state
        this.setState(prevState => ({
          uploadRows: [...prevState.uploadRows, {filename: file.name, uploadInfo, showTooltip: false}]
        }));

        this.setState({ hideListItems: "" });
      })
      .catch(error => {
        this.setState({ errorMessage: error });
      });
  },

  handleClick: function(index) {
    this.setState({ hideErrorMessage: "hidden" });

    // Toggle the showTooltip state
    this.setState(prevState => {
      const newRows = [...prevState.uploadRows];
      newRows[index].showTooltip = !newRows[index].showTooltip;
      return {uploadRows: newRows};
    });

    // Hide the tooltip after 5 seconds
    if (!this.state.uploadRows[index].showTooltip) {
      setTimeout(() => {
        this.setState(prevState => {
          const newRows = [...prevState.uploadRows];
          newRows[index].showTooltip = false;
          return {uploadRows: newRows};
        });
      }, 5000);
    }
  },
  handleRemove: function(index) {
    this.setState(function(prevState) {
      const newRows = [...prevState.uploadRows];
      newRows.splice(index, 1);
      const hideListItems = newRows.length === 0 ? "hidden" : "";
      return { uploadRows: newRows, hideListItems: hideListItems,  fileValue: ''  };
    });
  },

  renderUploadRow: function(rowData, index) {
  const { filename, uploadInfo, showTooltip } = rowData;
  const { uploadedSamplesCount, notFoundUuids, errorMessage } = uploadInfo;
  const batchesNotFound = notFoundUuids.length;
  const batchesText = batchesNotFound == 1 ? 'batch' : 'batches';
  const samplesText = uploadedSamplesCount == 1 ? 'sample' : 'samples';

  const tooltipText = notFoundUuids.slice(0, 5).map((batch_number) => <div>{batch_number}</div>);

  const rowContent = errorMessage ?
    <div className="uploaded-samples-count">
      {uploadedSamplesCount} {samplesText}
      {batchesNotFound > 0 && (
        <span className="dashed-underline">
          {" ("}{batchesNotFound} {batchesText} not found{")"}
        </span>
      )}
    </div> :
    <div className="uploaded-samples-count">
      {errorMessage}
    </div>;

  return (
    <div className="items-row" key={filename}>
      <div className="items-item gap-5">
        <div className="icon-circle-minus icon-gray remove_file" onClick={() => this.handleRemove(index)}></div>
        <div className="file-name">{filename}</div>
      </div>
      <div className={`items-row-action gap-5 not_found_message ${batchesNotFound > 0 ? ' ttip ' : ' '} ${batchesNotFound > 0 || errorMessage ? ' input-required ' : ' '}}`}
           onClick={() => this.handleClick(index)}>
        {rowContent}
        <div className={`upload-icon bigger ${batchesNotFound > 0 || errorMessage ? 'icon-alert icon-red' : 'icon-check'}`}></div>
        {batchesNotFound > 0 && (
          <div className={`ttext not-found-uuids ${showTooltip ? '' : 'hidden'}`}>
            {tooltipText}
          </div>
        )}
      </div>
    </div>
  );
},

  handleFileSelect: function(index) {
    this.aRef.click(); // Trigger file input click event
  },

render() {
  const { hideListItems, uploadRows, fileValue, errorMessage, hideErrorMessage } = this.state;
  return (
    <div>
      <div className={`csv-file-error row errors  ${hideErrorMessage ? 'hidden' : ''}`}>
        {errorMessage}
      </div>
     <div className={`list-items upload_info add-file-btn ${hideListItems ? 'hidden' : ''}`}>
       {uploadRows.map(this.renderUploadRow)}
     </div>
     <div className="items-count">
       <label htmlFor="csv-file" className="btn-link">
         <div className="icon-circle-plus icon-blue icon-margin"></div>
         <span className="btn-upload"> Add file</span>
       </label>
       <input
         type="file"
         id="csv-file"
         name="box[csv_box]"
         className="csv_file hidden"
         accept="text/csv"
         onChange={this.handleChange}
         value={fileValue}
       />
     </div>
   </div>
  );
}
});
