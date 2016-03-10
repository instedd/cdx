var NonEditableMap = React.createClass({

  render: function() {
    return <div>
      <ReactLeaflet.Map ref="map" center={this.props.position} zoom={this.props.zoom} className="map">
        <ReactLeaflet.TileLayer
          url='http://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png'
          attribution='&copy; <a href="http://openstreetmap.org">OpenStreetMap</a> contributors, <a href="http://creativecommons.org/licenses/by-sa/2.0/">CC-BY-SA</a>'            />
        <ReactLeaflet.Marker position={this.props.position} />
      </ReactLeaflet.Map>
    </div>
  }

});
