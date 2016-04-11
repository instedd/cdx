var TestOrdersRow = React.createClass({
  render: function() {
    var data = this.props.row_data;
    return (
      <tr key={this.props.index}>
        <td>{data['test_order']}</td>
        <td>{data['date_ordered']}</td>
        <td>{data['ordered_by']}</td>
        <td>{data['outstanding']}</td>
      </tr>);
    }
  });
  

  var OutstandingTestsTable = React.createClass({
    getInitialState: function() {
      appendTitle=[{"test_order":""},
      {"date_ordered":""},
      {"ordered_by":""},
      {"outstanding":""}];

      appendTitleDirection=[{"test_order":""},
      {"date_ordered":""},
      {"ordered_by":""},
      {"outstanding":""}];

      appendTitleSelected=[{"test_order":true},
      {"date_ordered":false},
      {"ordered_by":false},
      {"outstanding":false}];

			if (this.props.data.length==0) {
				shouldHide=true;
			} else {
				shouldHide=false;
			}

      return {
        data: this.props.data,
        appendTitle: appendTitle,
        appendTitleDirection: appendTitleDirection,
        appendTitleSelected: appendTitleSelected,
        shouldHide: shouldHide
      };
    },
    getDefaultProps: function() {
      return {
        title: "Outstanding Tests",
        allowSorting: false,
        orderBy: ""
      }
    },
    setAppendTitleDirection : function(header,value, direction) {
      tempAppendTitle = this.state.appendTitle;
      tempAppendTitleDirection = this.state.appendTitleDirection;
      tempAppendTitleSelected = this.state.appendTitleSelected;

      for (var key in tempAppendTitle) {
        tempAppendTitle[key]="";
        appendTitleSelected[key]=false;
      }

      tempAppendTitle[header]=value;
      this.setState({appendTitle: tempAppendTitle});

      tempAppendTitleDirection[header]=direction;
      this.setState({appendTitleDirection: tempAppendTitleDirection});

      tempAppendTitleSelected[header]=true;
      this.setState({appendTitleSelected: tempAppendTitleSelected});

    },
    reorderData: function(new_data) {
      this.setState({data: new_data});
    },
    randomString: function(){
      return Math.random().toString(36);
    },

    render: function() {
      var sortableHeader = function (title, field) {
        if (this.props.allowSorting) {
          return <ClientSideSortableColumnHeader  appendTitleSelected={this.state.appendTitleSelected} appendTitle={this.state.appendTitle} appendTitleDirection={this.state.appendTitleDirection} setAppendTitle={this.setAppendTitleDirection} title={title} field={field} orderBy={"-test_order"} data={this.state.data}  reorderData={this.reorderData} />
        } else {
          return <th>{title}</th>;
          }
        }.bind(this);

        return (
          <div>
            <div className="row">
              <div className="col pe-8">
                <h1>Outstanding Tests ({this.state.data.length})</h1>
              </div>
            </div>
            <div className="row">
              <div className="col pe-12">
								<div className={this.state.shouldHide ? '' : 'hidden'}>
								<span className="horizontal-bar-value">There is no data to display</span>
								</div>
							<div className={this.state.shouldHide ? 'hidden' : ''}>
                <table className="table" cellPadding="0" cellSpacing="0" >
                  <colgroup>
                    <col width="25%" />
                    <col width="25%" />
                    <col width="25%" />
                    <col width="25%" />
                  </colgroup>
                  <thead>
                    <tr>
                      {sortableHeader("Test Order#", "test_order")}
                      {sortableHeader("Date Ordered", "date_ordered")}
                      {sortableHeader("Ordered by", "ordered_by")}
                      {sortableHeader("Outstanding days", "outstanding")}
                    </tr>

                  </thead>
                </table>
                <div className="table_scroll_container">
                  <table className="table scroll" cellPadding="0" cellSpacing="0"  id="outstanding_tests_table_chart" >
                    <colgroup>
                      <col width="25%" />
                      <col width="25%" />
                      <col width="25%" />
                      <col width="25%" />
                    </colgroup>
                    <tbody key={this.randomString()} >
                      {this.state.data.map(function(row_data,index) {
                        return <TestOrdersRow key={index} row_data={row_data} />;
                      }.bind(this))}
                    </tbody>
                  </table>
                 </div>
                </div>
              </div>
            </div>
          </div>
        );
      }
    });
