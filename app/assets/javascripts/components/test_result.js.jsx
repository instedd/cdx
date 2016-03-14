var AddItemSearchTestResultTemplate = React.createClass({
  render: function() {
    return (<span>{this.props.item.test_id} - {this.props.item.name} ({this.props.item.device.name})</span>);
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

var AssayQuantitativeResult = React.createClass({
  render: function() {
    var assay = this.props.assay;

    return (
      <span>
        {(assay.name || assay.condition).toUpperCase()}:
        &nbsp;
        {assay.quantitative_result}
      </span>);
  }
});

function splitAssays(assays) {
  var res = { qualitative: [], quantitative: [] }

  for(var i = 0; i < assays.length; i++) {
    var a = assays[i]
    if (a.result && a.result != "n/a") { res.qualitative.push(a); }
    if (a.quantitative_result && a.quantitative_result != "") { res.quantitative.push(a); }
  }

  return res;
}
