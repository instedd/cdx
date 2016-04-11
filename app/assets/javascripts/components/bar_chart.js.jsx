var BarChart = React.createClass({
	getInitialState: function() {
		if (this.props.data.length==0) {
			shouldHide=true;
		} else {
			shouldHide=false;
		};

    return {
      shouldHide: shouldHide
    };
  },
  getDefaultProps: function() {
    return {
      margin: {top: 20, right: 20, bottom: 30, left: 50},
      height: 500,
      x_labels: []
    }
  },

  componentDidMount: function() {
    if (!this.props.width) {
      this.setProps({
        width: this.refs.svg.getDOMNode().clientWidth
      })
    }
  },

  render: function() {
    if (this.props.width) {
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
          .attr("transform", "rotate(-65)")
          .style("text-anchor", "start");
      }

      var yAxis = d3.svg.axis()
        .scale(y)
        .tickSize(chartWidth)
        .orient("left")
        .ticks(10, "s");

      x.domain(this.props.data.map(function(d) { return d.label; }));
      y.domain([0, d3.max(this.props.data, function(d) { return d3.sum(d.values); })]);
    }

    var svgProps = {}
    if (this.props.width) {
      svgProps.viewBox = "0 0 " + this.props.width + " " + this.props.height
    }

    return (
	<div>
			<div className={this.state.shouldHide ? '' : 'hidden'}>
			<span className="horizontal-bar-value">There is no data to display</span>
			</div>
		  <div className={this.state.shouldHide ? 'hidden' : ''}>
       <div className="chart">
        <svg width="100%"
             height={this.props.height}
             ref="svg"
             {...svgProps} >
          { this.props.width ?
            <g transform={"translate(" + this.props.margin.left + "," + this.props.margin.top + ")"}>

              {/* Bars */}
              {this.props.data.map(function (d, i) {
                var sum = 0;
                return d.values.map(function (v, j) {
                  sum += v;
                  return (
                    <rect key={[i,j]}
                          className={"bar b" + j}
                          x={x(d.label)}
                          y={y(sum)}
                          width={x.rangeBand()}
                          height={chartHeight - y(v)} />
                  )
                });
              })}

              {/* X Axis */}
              <g className="x axis"
                 transform={"translate(0," + chartHeight + ")"}
                 ref={function(ref) { if (ref) { d3.select(ref.getDOMNode()).call(xAxis); rotateLabels(ref); }}} />

              {/* Y Axis */}
              <g className="y axis"
                 transform={"translate(" + chartWidth + ",0)"}
                 ref={function(ref) { if (ref) { d3.select(ref.getDOMNode()).call(yAxis) }}} >
                <text transform={"translate(" + (-chartWidth - this.props.margin.left) + ",0),rotate(-90)"}
                      y="6" dy=".71em" style={{textAnchor: 'end'}}>{this.props.y_label}</text>
              </g>
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

     </div>
    </div>
    );
  }
});
