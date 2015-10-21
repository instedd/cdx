var PieChart = React.createClass({
  getDefaultProps: function() {
    return {
      height: 250,
      width: 600,
      colors: ["#9D1CB2", "#F6B500", "#47B04B", "#009788", "#A05D56", "#D0743C", "#FF8C00"]
    }
  },

  render: function() {
    var radius = Math.min(this.props.width, this.props.height) / 2;

    var color = d3.scale.ordinal()
      .range(this.props.colors);

    var arc = d3.svg.arc()
      .outerRadius(radius - 10)
      .innerRadius(radius - 35);

    var pie = d3.layout.pie()
      .sort(null)
      .value(function(d) { return d.value; });

    var legendPos = d3.scale.ordinal()
      .domain(this.props.data.map(function(x, i) { return i; }))
      .rangePoints([-25 * (this.props.data.length - 1) / 2, 25 * (this.props.data.length - 1) / 2]);

    return (
      <svg className="chart"
           width={this.props.width}
           height={this.props.height}>
        <g transform={"translate(" + radius + "," + this.props.height / 2 + ")"}>
          {/* Total Count */}
          <text className="total"
                dy=".35em">{d3.sum(this.props.data, function(d) { return d.value })}</text>
          <text className="total legend"
                dy="2.5em">{this.props.label}</text>

          {/* Pie Slices */}
          {pie(this.props.data).map(function(d) {
            return (
              <g className="arc" key={d.data.label}>
                <path d={arc(d)} fill={color(d.data.label)}/>
              </g>
            );
          })}

          {/* Legends */}
          {this.props.data.map(function(d, i) {
            return (
              <g className="legend" key={d.label}
                 transform={"translate(" + (radius + 30) + "," + legendPos(i) + ")"}>
                <circle r="8" fill={color(d.label)} />
                <text dx="15" dy=".35em">{d.label}</text>
              </g>
            )
          })}
        </g>
      </svg>
    );
  }

})
