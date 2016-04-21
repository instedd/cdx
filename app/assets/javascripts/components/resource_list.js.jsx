var AddResourceSearchDeviceTemplate = React.createClass({
  render: function() {
    var device = this.props.item;
    return (<span data-uuid={device.uuid}>{device.name} (SN: {device.serial_number})</span>);
  }
});

var DeviceList = React.createClass({

  placeholder: function() {
    return this.props.isException ? "Add elements to the exception list" : "Add elements to the list"
  },

  render: function() {
    return (
      <div className="device-list">
        <ul className="devices">
          {this.props.devices.map((function(device, index) {
            return <li key={device.uuid}>{device.name} <a onClick={this.props.removeDevice.bind(null, index)}>X</a></li>;
          }).bind(this))}
        </ul>
        <AddItemSearch callback={'/roles/search_device?context=' + this.props.context} onItemChosen={this.props.addDevice} itemTemplate={AddResourceSearchDeviceTemplate} itemKey="uuid" placeholder={this.placeholder()} />
      </div>
    );
  }
});
