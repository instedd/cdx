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
      height: 500
    }
  },	
  render: function() {
    var data = this.props.data;

    var chart = document.getElementById("chart"),
    axisMargin = 20,
    margin = 20,
    valueMargin = 4,
    width = this.state.width,
    height = this.props.height,
    barHeight = (height-axisMargin-margin*2)* 0.4/data.length,
    barPadding = (height-axisMargin-margin*2)*0.6/data.length,
    data, bar, svg, scale, xAxis, labelWidth = 0;

    max = d3.max(data.map(function(i){ 
      return i[1];
    }));

    svg = d3.select(chart)
      .append("svg")
      .attr("width", this.state.width)
      .attr("height", this.props.height);

    bar = svg.selectAll("g")
      .data(data)
      .enter()
      .append("g");

    bar.attr("class", "horizontal-bar")
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
      .tickSize(-height + 2*margin + axisMargin)
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
    .on("mouseover",	function() {
      d3.select(this)
        .attr("fill", "grey");			
    })
    .on("mouseout", function(d, i) {
      // this.id
      d3.select(this)
        .attr("fill","#03A9F4");
    });

    bar.append("text")
      .attr("class", "horizontal-bar-value")
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

    svg.insert("g",":first-child")
      .attr("class", "horizontal-bar-axis")
      .attr("transform", "translate(" + (margin + labelWidth) + ","+ (height - axisMargin - margin)+")")
      .call(xAxis);	  

    return (
        <div >
        </div>
        );
  }
});
