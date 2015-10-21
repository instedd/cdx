var BarChart = React.createClass({
  getDefaultProps: function() {
    return {
      margin: {top: 20, right: 20, bottom: 30, left: 50},
      height: 500
    }
  },

  componentDidMount: function() {
    if (!this.props.width) {
      this.setProps({
        width: this.refs.svg.getDOMNode().clientWidth
      })
    }
  },

  render: function() {
    if (this.props.width) {
      var chartWidth = this.props.width - this.props.margin.left - this.props.margin.right,
          chartHeight = this.props.height - this.props.margin.top - this.props.margin.bottom;

      var x = d3.scale.ordinal()
        .rangeRoundBands([0, chartWidth], .25);

      var y = d3.scale.linear()
        .range([chartHeight, 0]);

      var xAxis = d3.svg.axis()
        .scale(x)
        .orient("bottom");

      var yAxis = d3.svg.axis()
        .scale(y)
        .tickSize(chartWidth)
        .orient("left")
        .ticks(10, "s");

      x.domain(this.props.data.map(function(d) { return d.label; }));
      y.domain([0, d3.max(this.props.data, function(d) { return d.value; })]);
    }

    return (
      <svg className="chart"
           width="100%"
           height={this.props.height}
           ref="svg">
        { this.props.width ?
          <g transform={"translate(" + this.props.margin.left + "," + this.props.margin.top + ")"}>

            {/* Bars */}
            {this.props.data.map(function (d, i) {
              return (
                <rect key={i}
                      className="bar"
                      x={x(d.label)}
                      y={y(d.value)}
                      width={x.rangeBand()}
                      height={chartHeight - y(d.value)} />
              )
            })}

            {/* X Axis */}
            <g className="x axis"
               transform={"translate(0," + chartHeight + ")"}
               ref={function(ref) { if (ref) { d3.select(ref.getDOMNode()).call(xAxis) }}} />

            {/* Y Axis */}
            <g className="y axis"
               transform={"translate(" + chartWidth + ",0)"}
               ref={function(ref) { if (ref) { d3.select(ref.getDOMNode()).call(yAxis) }}} >
              <text transform={"translate(" + (-chartWidth - this.props.margin.left) + ",0),rotate(-90)"}
                    y="6" dy=".71em" style={{textAnchor: 'end'}}>Tests run</text>
            </g>
          </g>
          : null }
      </svg>
    );
  }
});
