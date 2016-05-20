var GroupedHorizontalBarChart = React.createClass({
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
      bar_gap: 20,
      space_for_labels: 160,
      space_for_ticks: 60,
      space_for_legend: 200,
      fill_colour: '#03A9F4',
      colors: ["#9D1CB2", "#F6B500", "#47B04B", "#009788", "#A05D56", "#D0743C", "#FF8C00"],
      offcolor: "#434343",
    }
  },

  updateWindow: function(){
    var w = window,
        d = document,
        e = d.documentElement,
        g = d.getElementsByTagName('body')[0];
        x = w.innerWidth || e.clientWidth || g.clientWidth;
        y = w.innerHeight|| e.clientHeight|| g.clientHeight;
  },
  render: function() {
    var data = this.props.data;
    var barHeight = this.props.bar_height,
      groupHeight = barHeight * data.series.length,
      gapBetweenGroups = this.props.bar_gap,
      spaceForLabels = this.props.space_for_labels,
      spaceForTicks = this.props.space_for_ticks,
      spaceForLegend = this.props.space_for_legend,
      x_title_spacing = 12;

    var chart = document.getElementById(this.props.chart_div),
      axisMargin = 20,
      margin = 20,
      valueMargin = 4,
      chartWidth = this.state.width,
      bar, svg, scale, xAxis, labelWidth = 0;

    // Zip the series data together (first values, second values, etc.)
    var zippedData = [];
    for (var i=0; i<data.labels.length; i++) {
      for (var j=0; j<data.series.length; j++) {
        zippedData.push(data.series[j].values[i]);
      }
    }

    chartWidth -= (spaceForLabels + spaceForLegend);
    chartHeight = barHeight * zippedData.length + gapBetweenGroups * data.labels.length + spaceForTicks;

    if (data.labels.length==0) {
       chartHeight = 200;
    }

    max = d3.max(zippedData);

    // Color scale
    var color = d3.scale.category20();

    var x = d3.scale.linear()
      .domain([0, d3.max(zippedData)])
      .range([0, chartWidth]);

    var xAxisHeight=-chartHeight + 2*margin + axisMargin;
    var  xAxis = d3.svg.axis()
      .scale(x)
      .tickSize(xAxisHeight)
      .orient("bottom");

    var y = d3.scale.linear()
      .range([chartHeight + gapBetweenGroups, 0]);

    var yAxis = d3.svg.axis()
      .scale(y)
      .tickFormat('')
      .tickSize(0)
      .orient("left");

    // Specify the chart area and dimensions
    svg = d3.select(chart)
      .append("svg")
      .attr("width", "100%")
      .attr("height", chartHeight);

    // Create bars
    var bar = svg.selectAll("g")
      .data(zippedData)
      .enter().append("g")
      .attr("transform", function(d, i) {
        return "translate(" + spaceForLabels + "," + (i * barHeight + gapBetweenGroups * (0.5 + Math.floor(i/data.series.length))) + ")";
      });

    // Create rectangles of the correct width
    bar.append("rect")
      .attr("fill", function(d,i) { return color(i % data.series.length); })
      .attr("class", "bar")
      .attr("width", x)
      .attr("height", barHeight - 1);

    // Add text label in bar
    bar.append("text")
      .attr("class", "chart-value-item")
      .attr("x", function(d) { return x(d) + 2; })
      .attr("y", barHeight / 2)
      .attr("fill", "black")
      .attr("dy", ".35em")
      .text(function(d) { return d; });

    // Draw labels
    var labels_offset=100;
    bar.append("text")
      .attr("class", "chart-value-item")
      .attr("x", function(d) { return - labels_offset; })
      .attr("y", groupHeight / 2)
      .attr("dy", ".35em")
      .text(function(d,i) {
        if (i % data.series.length === 0)
        return data.labels[Math.floor(i/data.series.length)];
        else
        return ""}).each(function() {
          labelWidth = spaceForLabels;
        });

    scale = d3.scale.linear()
      .domain([0, max])
      .range([0, chartWidth - margin*2 - labelWidth]);

    xAxis11 = d3.svg.axis()
      .scale(scale)
      .tickSize(-chartHeight + 2*margin + axisMargin)
      .orient("bottom");

    svg.append("g")
      .attr("class", "y axis")
      .attr("transform", "translate(" + spaceForLabels + ", " + -gapBetweenGroups/2 + ")")
      .call(yAxis);

      // Draw legend
      var legendRectSize = 18,
      legendSpacing  = 4;

      var legend = svg.selectAll('.legend')
        .data(data.series)
        .enter()
        .append('g')
        .attr('transform', function (d, i) {
          var height = legendRectSize + legendSpacing;
          var offset = -gapBetweenGroups/2;
          var horz = spaceForLabels + chartWidth + 60 - legendRectSize;
          var vert = i * height - offset;
          return 'translate(' + horz + ',' + vert + ')';
        });

      legend.append('rect')
        .attr('width', legendRectSize)
        .attr('height', legendRectSize)
        .style('fill', function (d, i) { return color(i); })
        .style('stroke', function (d, i) { return color(i); });

      legend.append('text')
        .attr("class", "chart-value-item")
        .attr('x', legendRectSize + legendSpacing)
        .attr('y', legendRectSize - legendSpacing)
        .text(function (d) { return d.label; });

      if (data.labels.length==0) {
        svg.append("text")
          .attr("x", this.state.width / 2)
          .attr("y", chartHeight/2)
          .attr("dy", "-.7em")
          .attr("class", "chart-value-item")
          .style("text-anchor", "middle")
          .text("There is no data to display");
       }

      svg.insert("g",":first-child")
        .attr("class", "chart-axis")
        .attr("transform", "translate(" + (margin + spaceForLabels - 20) + ","+ (chartHeight - axisMargin + 8)+")")
        .call(xAxis);

      window.onresize = this.updateWindow;

      return (
        <div></div>
      );
    }
  });
