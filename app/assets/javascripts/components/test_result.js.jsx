var AddItemSearchTestResultTemplate = React.createClass({
  render: function() {
    return (<span>{this.props.item.test_id} - {this.props.item.name} ({this.props.item.device.name})</span>);
  }
});

var AssaysResult = React.createClass({
  // TODO allow assaysLayout so among different test results, the assays results are rendered in the same order and missing ones can be detected.
  render: function() {
    return (
      <span>
        {this.props.assays.map(function(assay) {
           return <AssayResult key={assay.condition} assay={assay}/>;
        })}
      </span>
    );
  }
});

var AssaysResultList = React.createClass({
  render: function() {
    return  (
      <div>
        {this.props.assays.map(function(assay, index) {
          return (
            <div className="row" key={index}>
              <div className="col pe-4">
                <div className="underline">
                  <span><b>{(assay.name || assay.condition).toUpperCase()}</b></span>
                </div>
              </div>
              <div className="col pe-3">
                <b>{_.capitalize(assay.result)}</b>
              </div>
              <div className="col pe-1">
                {assay.quantitative_result}
              </div>

            </div>
          );
        })}
      </div>
    );
  }
});

var AssayResult = React.createClass({
  render: function() {
    var assay = this.props.assay;

    return (
      <span className={"assay-result assay-result-" + assay.result}>
        {(assay.name || assay.condition).toUpperCase()}
      </span>);
  }
});
