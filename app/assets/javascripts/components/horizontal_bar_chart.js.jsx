var HorizontalBarChart = React.createClass({
  getInitialState: function() {
    var width_value = this.props.width || 0;
    return {
      width: width_value
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

  render: function() {
    var data = this.props.data;

    barHeight        = this.props.bar_height,
    groupHeight      = barHeight * data.length,
    gapBetweenGroups = this.props.bar_gap,
    spaceForLabels   = this.props.space_for_labels,
    spaceForLegend   = this.props.space_for_legend;

    var chart = document.getElementById(this.props.chart_div),
    axisMargin = 20,
    margin = 20,
    valueMargin = 4,
    width = this.state.width,
    barPadding = 20,
    data, bar, svg, scale, xAxis, labelWidth = 0,
    chartHeight = (barHeight * (data.length+1)) + (gapBetweenGroups * (data.length+1));

    max = d3.max(data.map(function(i){ 
      return i[1];
    }));

    if (data.length==0) {
      chartHeight = 200;
    }

    svg = d3.select(chart)
      .append("svg")
      .attr("width", this.state.width)
      .attr("height", chartHeight);

    bar = svg.selectAll("g")
      .data(data)
      .enter()
      .append("g");

    bar.attr("class", "chart-base")
      .attr("cx",0)
      .attr("transform", function(d, i) { 
        return "translate(" + margin + "," + (i * (barHeight + barPadding) + barPadding) + ")";
      });

    bar.append("text")
      .attr("class", "horizontal-bar-label")
      .attr("y", barHeight / 2)
      .attr("dy", ".35em") //vertical align middle
      .text(function(d){
        return d[0];
      }).each(function() {
        labelWidth = Math.ceil(Math.max(labelWidth, this.getBBox().width));
      });

    scale = d3.scale.linear()
      .domain([0, max])
      .range([0, width - margin*2 - labelWidth]);

    xAxis = d3.svg.axis()
      .scale(scale)
      .tickSize(-chartHeight + 2*margin + axisMargin)
      .orient("bottom");

    bar.append("rect")
      .attr("transform", "translate("+labelWidth+", 0)")
      .attr("height", barHeight)
      .attr("width", function(d){
        return scale(d[1]);
      })
    .attr("id", function(d, i) {
      return i;
    })
    .on("mouseover",  function() {
      d3.select(this)
        .attr("fill", this.props.offcolor);
    })
    .on("mouseout", function(d, i) {
      // this.id
      d3.select(this)
        .attr("fill",this.props.fill_colour);
    });

    bar.append("text")
      .attr("class", "chart-value-item")
      .attr("y", barHeight / 2)
      .attr("dx", -valueMargin + labelWidth) //margin right
      .attr("dy", ".35em") //vertical align middle
      .attr("text-anchor", "end")
      .text(function(d){
        if (d[1]>0) {
          return d[1];
        } else {
          return "";
        }
      })
    .attr("x", function(d){
      var width = this.getBBox().width;
      return Math.max(width + valueMargin, scale(d[1]));
    });

    var canvasWidth = this.props.width,
    canvasHeight = chartHeight,
    otherMargins = canvasWidth * 0.1,
    leftMargin = canvasWidth * 0.25,
    maxBarWidth = canvasHeight - - otherMargins - leftMargin
      maxChartHeight = canvasHeight - (otherMargins * 2);

    //x axis title        
    svg.append("text")
      .attr("x", (maxBarWidth / 2) + leftMargin)
      .attr("y", chartHeight - (otherMargins / 8))
      .attr("text-anchor", "middle")
      .attr("font-family", "sans-serif")
      .attr("font-size", "14px")
      .attr("font-weight", "bold")
      .attr("fill", "black")
      .text(this.props.label);                                

    if (data.length==0) {
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
      .attr("transform", "translate(" + (margin + labelWidth) + ","+ (chartHeight - axisMargin - margin)+")")
      .call(xAxis);    

    return (
        <div>
        </div>
        );
  }
});
