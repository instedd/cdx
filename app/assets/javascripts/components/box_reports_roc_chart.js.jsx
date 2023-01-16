var BoxReportsRocChart = React.createClass({
    getDefaultProps: function() {
      return {
        margin: {top: 50, right: 50, bottom: 50, left: 50},
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
  
        x.domain([0,1]);
        y.domain([0,1]);
      }

      var svgProps = {}
      if (this.props.width) {
        svgProps.viewBox = "0 0 " + this.props.width + " " + this.props.height
      }

      data = this.props.data; 
      marginLeft = this.props.margin.left; 
      marginTop = this.props.margin.top; 

      var pathLine = function () {
        d3.select("svg#rocchart").append("path")
          .datum(data)
          .attr("transform", "translate(0," + marginTop + ")")
          .attr("class", "roc-line")
          .attr("d", d3.svg.line()
            .x(function(d) { return x(d[0])+marginLeft })
            .y(function(d) { return y(d[1]) })
            )
      }
  
      return (
        <div className="chart">
          <svg id="rocchart"
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
                        y="6" dy=".1em" style={{textAnchor: 'end'}}>FALSE POSITIVE RATE</text>
  
                {/* Y Axis */}
                <g className="y axis"
                   transform={"translate(" + chartWidth + ",0)"}
                   ref={function(ref) { if (ref) { d3.select(ref.getDOMNode()).call(yAxis) }}} >
                  <text transform={"translate(" + (-chartWidth - this.props.margin.left) + ",0),rotate(-90)"}
                        y="6" dy=".71em" style={{textAnchor: 'end'}}>TRUE POSTIVE RATE</text>
                </g>

                {/* Line */}
                {pathLine()}

            {/* Threshold fpr */}
            <line id="threshold-fpr-down"
                  className={"bar b1"}
                  x1={x(x.domain()[0])}
                  y1={y(y.domain()[0])}
                  x2={x(x.domain()[0])}
                  y2={y(y.domain().slice(-1))}
                  hidden={true}
                />
            <line id="threshold-fpr-up"
                  className={"bar b1"}
                  x1={x(x.domain()[1])}
                  y1={y(y.domain()[0])}
                  x2={x(x.domain()[1])}
                  y2={y(y.domain().slice(-1))}
                  hidden={true}
                />
            <line id="threshold-fpr"
                  className={"bar b1"}
                  x1={x(x.domain()[0])}
                  y1={y(y.domain()[0])}
                  x2={x(x.domain()[0])}
                  y2={y(y.domain().slice(-1))}
                  stroke={"black"}
                  strokeDasharray={"5,5"}
                />

            {/* Threshold tpr */}
            <line id="threshold-tpr-down"
                  className={"bar b1"}
                  x1={x(x.domain()[0])}
                  y1={y(y.domain()[0])}
                  x2={x(x.domain().slice(-1))}
                  y2={y(y.domain()[0])}
                  hidden={true}
                />
            <line id="threshold-tpr-up"
                  className={"bar b1"}
                  x1={x(x.domain()[0])}
                  y1={y(y.domain()[1])}
                  x2={x(x.domain().slice(-1))}
                  y2={y(y.domain()[1])}
                  hidden={true}
                />
            <line id="threshold-tpr"
                  className={"bar b1"}
                  x1={x(x.domain()[0])}
                  y1={y(y.domain()[0])}
                  x2={x(x.domain().slice(-1))}
                  y2={y(y.domain()[0])}
                  stroke={"black"}
                  strokeDasharray={"5,5"}
                />


              </g>
              : null }
          </svg>
        </div>
      );
    }
  });
  