var GroupedVerticalBarChart = React.createClass({
  getInitialState: function() {
    var width_value = this.props.width || 400;
    return {
      width: width_value,
    };
  },
  render: function() {
    var margin = {top: 20, right: 20, bottom: 30, left: 50},
    width = this.props.width - margin.left - margin.right,
    height = this.props.height - margin.top - margin.bottom;

    var chart = document.getElementById(this.props.chart_div);

    var x0 = d3.scale.ordinal()
    .rangeRoundBands([0, width], .1);

    var x1 = d3.scale.ordinal();

    var y = d3.scale.linear()
    .range([height, 0]);

    var color = d3.scale.ordinal()
    .range(["#98abc5", "#8a89a6", "#7b6888", "#6b486b", "#a05d56", "#d0743c", "#ff8c00"]);

    var xAxis = d3.svg.axis()
    .scale(x0)
    .orient("bottom");

    var yAxis = d3.svg.axis()
    .scale(y)
    .orient("left")
    .tickFormat(d3.format(".2s"));

    var svg = d3.select(chart).append("svg")
    .attr("width", width + margin.left + margin.right)
    .attr("height", height + margin.top + margin.bottom)
    .append("g")
    .attr("transform", "translate(" + margin.left + "," + margin.top + ")");
/*
    all_data=[
      {'site': 'site1', 'peak': 72, 'average' : 44},
      {'site': 'site2', 'peak': 62, 'average' : 54},
      {'site': 'site4', 'peak': 92, 'average' : 64},
    ];
*/
    all_data = this.props.data;

    var legendNames = d3.keys(all_data[0]).filter(function(key) { return key !== "site"; });
    all_data.forEach(function(d) {   d.tests = legendNames.map(function(name) { return {name: name, value: +d[name]}; });  });

    x0.domain(all_data.map(function(d) { return d.site; }));

    x1.domain(legendNames).rangeRoundBands([0, x0.rangeBand()]);

    y.domain([0, d3.max(all_data, function(d) { return d3.max(d.tests, function(d) { return d.value; }); })]);

    svg.append("g")
    .attr("class", "x axis")
    .attr("transform", "translate(0," + height + ")")
    .call(xAxis);

    svg.append("g")
    .attr("class", "y axis")
    .call(yAxis)
    .append("text")
    .attr("transform", "rotate(-90)")
    .attr("y", 6)
    .attr("dy", ".71em")
    .style("text-anchor", "end")
    .text("# tests");

    var state = svg.selectAll(".state")
    .data(all_data)
    .enter().append("g")
    .attr("class", "state")
    .attr("transform", function(d) { return "translate(" + x0(d.site) + ",0)"; });

    state.selectAll("rect")
    .data(function(d) { return d.tests; })
    .enter().append("rect")
    .attr("width", x1.rangeBand())
    .attr("x", function(d) { return x1(d.name); })
    .attr("y", function(d) { return y(d.value); })
    .attr("height", function(d) { return height - y(d.value); })
    .style("fill", function(d) { return color(d.name); });

    var legend = svg.selectAll(".legend")
    .data(legendNames.slice().reverse())
    .enter().append("g")
    .attr("class", "legend")
    .attr("transform", function(d, i) { return "translate(0," + i * 25 + ")"; });

    legend.append("rect")
    .attr("x", width - 1)
    .attr("width", 18)
    .attr("height", 18)
    .style("fill", color);

    legend.append("text")
    .attr("x", width - 5)
    .attr("y", 9)
    .attr("dy", ".35em")
    .style("text-anchor", "end")
    .text(function(d) { return d; });

    if (data.length==0) {
      svg.append("text")
      .attr("x", this.props.width/2)
      .attr("y", this.props.height/2)
      .attr("dy", "-.7em")
      .attr("class", "horizontal-bar-value")
      .style("text-anchor", "middle")
      .text("There is no data to display");
    }

    return (
      <div>
      </div>
    );
  }
});
