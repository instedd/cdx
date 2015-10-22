var AddItemSearchSampleTemplate = React.createClass({
  render: function() {
    return (<span>{this.props.item.entity_ids[0]} ({this.props.item.uuid})</span>);
  }
});

var Sample = React.createClass({

  unifySample: function(event) {
    this.props.onUnifySample(this.props.sample);
    event.preventDefault();
  },


  render: function() {
    // TODO add barcode
    // TODO add printer

    var unifiedSamples = null;
    if (this.props.sample.entity_ids.length > 1) {
      unifiedSamples = (
        <div>
          <span>Unified samples</span>
          <ul>
            {_(this.props.sample.entity_ids).rest().map(function(entity_id) {
              return (<li key={entity_id}>{entity_id}</li>);
            }).value()}
          </ul>
        </div>);
    }

    var unifySampleAction = null;
    if (this.props.onUnifySample) {
      unifySampleAction = (<div><a onClick={this.unifySample}>Unify sample</a><br/></div>);
    }

    return (
    <li>
      {unifySampleAction}
      {this.props.sample.entity_ids[0]} ({this.props.sample.uuid})
      {unifiedSamples}
    </li>);
  }
});

var SamplesList = React.createClass({
  render: function() {
    var _this = this;
    return (
      <ul>
        {this.props.samples.map(function(sample) {
           return <Sample key={sample.uuid} sample={sample} onUnifySample={_this.props.onUnifySample}/>;
        })}
      </ul>
    );
  }
});
