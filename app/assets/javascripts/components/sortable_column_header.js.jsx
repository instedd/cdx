var SortableColumnHeader = React.createClass({
  render: function() {
    var field = this.props.field;
    var descField = "-" + field;
    var orderByThis = false;
    var orderByThisDir = null;
    var appendTitle = null;

    var nextOrder = field;

    if (this.props.orderBy == field) {
      orderByThis = true;
      orderByThisDir = 'asc';
      nextOrder = descField;
      appendTitle = " ↑";
    } else if (this.props.orderBy == descField) {
      orderByThis = true;
      orderByThisDir = 'desc';
      appendTitle = " ↓";
    }

    var sortUrl = URI(window.location.href).setSearch({"order_by": nextOrder});

    return (<th>
        <a href={sortUrl} className={classNames({ordered: orderByThis, ["ordered-" + orderByThisDir]: orderByThis})}>{this.props.title} {appendTitle}</a>
      </th>);
  },
});
