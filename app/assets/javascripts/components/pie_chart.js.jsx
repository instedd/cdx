var PieChart = React.createClass({
  getDefaultProps: function() {
    return {
      height: 250,
      width: 600,
      colors: ["#9D1CB2", "#F6B500", "#47B04B", "#009788", "#A05D56", "#D0743C", "#FF8C00"],
      offcolor: "#434343",
    }
  },

  buildColorScale: function () {
    return d3.scale.ordinal().range(this.props.colors);
  },

  componentDidMount: function () {
    var svg = d3.select(this.refs.svg.getDOMNode());
    var data = this.props.data;


    var arcs_path = svg.selectAll(".arc path").data(data);
    var g_legends = svg.selectAll("g.legend").data(data);

    var main_total = svg.selectAll(".main.total");
    var details_total = svg.selectAll(".details.total");
    var details_total_number = svg.selectAll(".details.total.number");
    var details_total_legend = svg.selectAll(".details.total.legend");

    var stopOngoingAnimations = function () {
      arcs_path.transition().duration(0);
      main_total.transition().duration(0);
      details_total.transition().duration(0);
    };

    // source: http://stackoverflow.com/a/32129715/30948
    function wrapWithEllipsis( d ) {
        var self = d3.select(this),
            textLength = self.node().getComputedTextLength(),
            text = self.text();
        while ( ( textLength > self.attr('width') )&& text.length > 0) {
            text = text.slice(0, -1);
            self.text(text + '...');
            textLength = self.node().getComputedTextLength();
        }
    }

    var showItemPercentage = function (hoverItem) {
      stopOngoingAnimations();
      var color = this.buildColorScale();

      details_total_number.text(hoverItem.value);
      details_total_legend.text(hoverItem.label).each(wrapWithEllipsis);

      main_total.transition().style('opacity', 0).each("end", function(){
        details_total.transition().style('opacity', 1);
      });

      arcs_path.transition().attr('fill', function(d) {
        var c = color(d.label);
        return hoverItem == d ? c : this.props.offcolor;
      }.bind(this));
    }.bind(this);

    var showOverall = function() {
      stopOngoingAnimations();
      var color = this.buildColorScale();
      details_total.transition().style('opacity', 0).each("end", function(){
        main_total.transition().style('opacity', 1);
      });
      arcs_path.transition().attr('fill', function(d) {
        return color(d.label);
      }.bind(this));
    }.bind(this);

    arcs_path
      .on('mouseover', showItemPercentage)
      .on('mouseleave', showOverall);

    g_legends
      .on('mouseover', showItemPercentage)
      .on('mouseleave', showOverall);
  },

  render: function() {
    var radius = Math.min(this.props.width, this.props.height) / 2;

    var color = this.buildColorScale();

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
           height={this.props.height} ref="svg">
        <g transform={"translate(" + radius + "," + this.props.height / 2 + ")"}>
          {/* Total Count */}
          <text className="main total"
                dy=".35em">{d3.sum(this.props.data, function(d) { return d.value })}</text>
          <text className="main total legend"
                dy="2.5em">{this.props.label}</text>

          {/* Details Count */}
          <text className="details total number"
                dy=".35em"></text>
          <text className="details total legend" width="135"
                dy="2.5em"></text>

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
