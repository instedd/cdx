var SamplesReportsBarChart = React.createClass({
  getDefaultProps: function() {
    return {
      margin: {top: 20, right: 20, bottom: 50, left: 50},
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
    var barVariable = this.props.barVariable
    var errorBarsVariable = this.props.errorBarsVariable

    if (this.props.width) {
      this.props.margin.bottom = d3.max(this.props.data.map(function(d) { return d.label.toString().length*8; }))+30

      var chartWidth = this.props.width - this.props.margin.left - this.props.margin.right,
          chartHeight = this.props.height - this.props.margin.top - this.props.margin.bottom;

      var x = d3.scale.ordinal()
        .rangeRoundBands([0, chartWidth], .25);

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

      x.domain(this.props.data.map(function(d) { return d.label; }));
      // first option: y domain goes up to the max avg
      var yDomainMax = d3.max(this.props.data.map( function(d) { return d3.sum(d[barVariable]); }))
      // if error bars are present, y domain goes up to the max avg + max error bar
      this.props.data.map( function(d) { 
        d[barVariable].map(function (num, idx) {
          yDomainMax = d3.max([yDomainMax, num + d[errorBarsVariable][idx]**(1/2)]);
        })
      })
      y.domain([0, yDomainMax]);
      
    }

    var svgProps = {}
    if (this.props.width) {
      svgProps.viewBox = "0 0 " + this.props.width + " " + this.props.height
    }

    return (
      <div className="chart"
            id="barchart-container">
        <svg id="barchart" 
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

              {/* Bars */}
              {this.props.data.map(function (d, i) {
                return d[barVariable].map(function (v, j) {
                  return (
                    <rect key={[i,j]}
                          className={"bar b" + (d.isDistractor ?"1":"0")}
                          x={x(d.label)}
                          y={y(v)}
                          width={x.rangeBand()}
                          height={chartHeight - y(v)} />
                  )
                });
              })}


              {/* Error Bars */}
              {this.props.data.map(function (d, i) {
                if (d[errorBarsVariable].length > 2){
                  error = d3.mean(d[errorBarsVariable])
                  return (
                    <g key={[i]}
                      className={"errorbar"}>
                      <rect 
                            x={x(d.label)+x.rangeBand()/2-1}
                            y={y(d[barVariable]) - error}
                            width={2}
                            height={error*2} />
                      <rect 
                            x={x(d.label)}
                            y={y(d[barVariable]) - error - 1}
                            width={x.rangeBand()}
                            height={2} />
                      <rect 
                            x={x(d.label)}
                            y={y(d[barVariable]) + error + 1}
                            width={x.rangeBand()}
                            height={2} />
                      
                    </g>
                  )
                }
                else
                  return null;
              }
            )}

            {/* Threshold line */}
            <line id="threshold-line-down"
                  className={"bar b1"}
                  x1={x(x.domain()[0])}
                  y1={y(y.domain()[0])}
                  x2={x(x.domain().slice(-1))}
                  y2={y(y.domain()[0])}
                  hidden={true}
                />
            <line id="threshold-line-up"
                  className={"bar b1"}
                  x1={x(x.domain()[0])}
                  y1={y(y.domain()[1])}
                  x2={x(x.domain().slice(-1))}
                  y2={y(y.domain()[1])}
                  hidden={true}
                />
            <line id="threshold-line"
                  className={"bar b1"}
                  x1={x(x.domain()[0])}
                  y1={y(y.domain()[0])}
                  x2={x(x.domain().slice(-1))+x.rangeBand()}
                  y2={y(y.domain()[0])}
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
