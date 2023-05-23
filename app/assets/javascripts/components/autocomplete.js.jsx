var Autocomplete = React.createClass({
  getInitialState: function() {
    return {
      data: JSON.parse(this.props.data),
      inputValue: "",
      fieldName: this.props.name // Initial fieldName value
    };
  },

  reset: function() {
    this.setState({ data: [""] });
  },

  handleInputChange: function(event) {
    const value = event.target.value;
    this.setState({ inputValue: value });
  },

  handleOptionClick: function(option) {

    this.setState({ inputValue: option });
  },
  render: function() {
    const { data, inputValue, fieldName } = this.state;
    const filteredData = data.filter(item => item && item.toLowerCase().indexOf(inputValue.toLowerCase()) !== -1);
    return (
      <div>
        <input
          type="text"
          name={fieldName}
          value={inputValue}
          onChange={this.handleInputChange}
          autoComplete="off"
          placeholder="Search..."
        />
         <div className={inputValue ? "" : "hidden"}>
           {filteredData.map((option, index) => (
             <div key={index} onClick={() => this.handleOptionClick(option)}>
               {option}
             </div>
           ))}
         </div>
      </div>
    );
  }
});
