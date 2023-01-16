var BoxReportsLineChart = React.createClass({
    getDefaultProps: function() {
      return {
        margin: {top: 0, right: 50, bottom: 50, left: 50},
        x_labels: []
      }
    },
  
    componentDidMount: function() {
      if (!this.props.width) {
        this.setProps({
          width: 700,
          height: 400
        })
      }
    },
  
    render: function() {
      var dotsVariable = this.props.dotsVariable
  
      if (this.props.width) {
        var chartWidth = this.props.width - this.props.margin.left - this.props.margin.right,
            chartHeight = this.props.height - this.props.margin.top - this.props.margin.bottom;
  
        var x = d3.scale.linear()
          .range([0, chartWidth]);
  
        var y = d3.scale.linear()
          .range([chartHeight, 0]);
  
        var xAxis = d3.svg.axis()
          .scale(x)
          .orient("bottom");
  
        var rotateLabels = function(dom) {
          d3.select(dom.getDOMNode()).selectAll("text")
            .attr("y", 0)
            .attr("x", 9)
            .attr("dy", ".35em")
            .attr("transform", "rotate(65)")
            .style("text-anchor", "start");
        }
  
        var yAxis = d3.svg.axis()
          .scale(y)
          .tickSize(chartWidth)
          .orient("left")
          .ticks(10, "s");
  
        x.domain([d3.min(this.props.data, function(d) { return parseFloat(d.label); }), d3.max(this.props.data, function(d) { return parseFloat(d.label)*1.05; })]);
        y.domain([0, d3.max(this.props.data, function(d) { return d3.max(d[dotsVariable])*1.05; })]);

        var linearRegression = function (data) {
          var xValues = []
          var yValues = []
          
          data.forEach( (d) => 
          {
            d[dotsVariable].forEach ( (e) => {
              xValues.push(parseFloat(d.label))
              yValues.push(parseFloat(e))
            })
          })

          var xMean = d3.mean(xValues);
          var yMean = d3.mean(yValues);
    
          // Calculate the differences between each x and y value and their means
          var xDifferences = [];
          var yDifferences = [];
    
          for (var i = 0; i < xValues.length; i++) {
            xDifferences.push(xValues[i] - xMean);
            yDifferences.push(yValues[i] - yMean);
          }
    
          // Calculate the sum of the squares of the differences
          var sumOfSquares = 0;
    
          for (var i = 0; i < xDifferences.length; i++) {
            sumOfSquares += xDifferences[i] * yDifferences[i];
          }

          var squaredDiffs = 0
          for (var i = 0; i < xDifferences.length; i++) {
            squaredDiffs += Math.pow(xDifferences[i], 2);
          }

          // Calculate the slope of the regression line
          var slope = sumOfSquares / squaredDiffs;
    
          // Calculate the y-intercept of the regression line
          var yIntercept = yMean - (slope * xMean);
          
          return [slope, yIntercept];
        };
    
        var regressionLine = linearRegression(this.props.data);
      }
  
      var svgProps = {}
      if (this.props.width) {
        svgProps.viewBox = "0 0 " + this.props.width + " " + this.props.height
      }
  
      return (
        <div className="chart">
          <svg id="linechart"
               width="100%"
               height={this.props.height}
               ref="svg"
               {...svgProps} >
            { this.props.width ?
              <g transform={"translate(" + this.props.margin.left + "," + this.props.margin.top + ")"}>
  
                {/* X Axis */}
                <g className="x axis"
                   transform={"translate(0," + chartHeight + ")"}
                   ref={function(ref) { if (ref) { d3.select(ref.getDOMNode()).call(xAxis); rotateLabels(ref); }}}>
                </g>
                <text transform={"translate(" + (chartWidth) + ", "+(chartHeight+this.props.margin.bottom-10)+")"}
                        y="6" dy=".1em" style={{textAnchor: 'end'}}>CONCENTRATION (copies/ml)</text>
  
                {/* Y Axis */}
                <g className="y axis"
                   transform={"translate(" + chartWidth + ",0)"}
                   ref={function(ref) { if (ref) { d3.select(ref.getDOMNode()).call(yAxis) }}} >
                  <text transform={"translate(" + (-chartWidth - this.props.margin.left) + ",0),rotate(-90)"}
                        y="6" dy=".71em" style={{textAnchor: 'end'}}>{this.props.y_label}</text>
                </g>
  
                {/* Dots */}
                {this.props.data.map(function (d, i) {
                  var sum = 0;
                  return d[dotsVariable].map(function (v, j) {
                    sum += v;
                    return (
                      <circle key={[i,j]}
                            className={"circle"}
                            cx={x(d.label)}
                            cy={y(v)}
                            r={3} />
                    )
                  });
                })}

                {/* Linear Regression */}
                <line className={"bar b1"}
                  x1={x(x.domain()[0])}
                  y1={y(regressionLine[1])}
                  x2={x(x.domain()[1])}
                  y2={y(x.domain()[1]*regressionLine[0]+regressionLine[1])}
                  stroke={"black"}
                  strokeDasharray={"5,5"}
                />

              </g>
              : null }
          </svg>
          <div className="legends">
            {this.props.x_labels.map(function (d, i) {
              return (
                <span key={i}>
                  <svg width="16" height="16">
                    <circle r="8" className={"bar b" + i} transform="translate(8, 8)" />
                  </svg>
                  {d}
                </span>
              );
            })}
          </div>
        </div>
      );
    }
  });
  