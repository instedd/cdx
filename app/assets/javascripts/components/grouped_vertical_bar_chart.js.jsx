var GroupedVerticalBarChart = React.createClass({ 
  getInitialState: function() {
    var width_value = this.props.width || 400;
    return {
      width: width_value,
    };
  },
  getDefaultProps: function() {
    return {
      margin: {top: 20, right: 20, bottom: 30, left: 50},
      height: 250,
      bar_height: 30,
      bar_gap: 40,
      space_for_labels: 160,
      space_for_ticks: 60,
      space_for_legend: 200,
      fill_colour: '#03A9F4',
      colors: ["#9D1CB2", "#F6B500", "#47B04B", "#009788", "#A05D56", "#D0743C", "#FF8C00"],
      offcolor: "#434343",
    }
  },

  render: function() {
    var margin = this.props.margin,
      width = this.props.width - margin.left - margin.right,
      height = this.props.height - margin.top - margin.bottom;

    var chart = document.getElementById(this.props.chart_div);

    var x0 = d3.scale.ordinal()
      .rangeRoundBands([0, width], .1);

    var x1 = d3.scale.ordinal();

    var y = d3.scale.linear()
      .range([height, 0]);

    var color = d3.scale.ordinal()
      .range(this.props.colors);

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

    all_data = this.props.data;

    var legendNames = d3.keys(all_data[0]).filter(function(key) { return key !== "site"; });
    all_data.forEach(function(d) {   d.tests = legendNames.map(function(name) { return {name: name, value: +d[name]}; });  });

    x0.domain(all_data.map(function(d) { return d.site; }));

    x1.domain(legendNames).rangeRoundBands([0, x0.rangeBand()]);

    y.domain([0, d3.max(all_data, function(d) 
      { 
        return d3.max(d.tests, function(d) 
          { 
            return d.value; 
          }); 
      })
    ]);

    svg.append("g")
      .attr("class", "x axis")
      .attr("transform", "translate(0,)")
      .call(xAxis);

    // Vertical Axis
    svg.append("g")
      .attr("class", "y axis")
      .call(yAxis)
      .append("text")
      .attr("transform", "rotate(-90)")
      .attr("y", 6)
      .attr("dy", ".71em")  // align top
      .style("text-anchor", "end")
      .text("# tests");

    var state = svg.selectAll(".state")
      .data(all_data)
      .enter()
      .append("g")
      .attr("class", "state")
      .attr("transform", function(d) { return "translate(" + x0(d.site) + ",0)"; });

    // all bars within site
    var barWidth = x1.rangeBand() / 2;
    state.selectAll("rect")
      .data(function(d) { return d.tests; })
      .enter()
      .append("rect")
      .attr("width", barWidth )
      .attr("x", function(d) { return x1(d.name); })
      .attr("y", function(d) { return 0; })
      .attr("height", function(d) { return y(d.value); })
      .style("fill", function(d) { return color(d.name); })

      .append("rect")
      .attr("width", barWidth )
      .attr("x", function(d) { return x1(d.name) + barWidth; })
      .attr("y", function(d) { return 0; })
      .attr("height", function(d) { return y(d.value); })
      .style("fill", function(d) { return color(d.name); });


      // legend
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

    if (all_data.length == 0) {
      svg.append("text")
        .attr("x", this.props.width/2)
        .attr("y", this.props.height/2)
        .attr("dy", "-.7em")
        .attr("class", "chart-value-item")
        .style("text-anchor", "middle")
        .text("There is no data to display");
    }

    return (
      <div> </div>
    );
  }
});
