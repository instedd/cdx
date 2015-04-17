$(function() {

  var formatLocation = function(location) {
    var name = location.name;
    if (location.ancestors.length > 0) {
      var ancestorsNames = _.pluck(location.ancestors, 'name');
      name += (" (" + ancestorsNames.reverse().join(", ") + ")");
    }
    return {
      id: location.id,
      text: name
    }
  };

  $('#laboratory_location_geoid').select2({
    placeholder: "Search locations",
    minimumInputLength: 2,
    ajax: {
      url: gon.location_service_url + "/suggest",
      dataType: 'json',
      quietMillis: 250,
      data: function (term, page) {
        return {
          name: term,
          limit: 20,
          offset: page * 20,
          ancestors: true,
          set: gon.location_service_set
        };
      },
      results: function (data, page) {
        return {
          more: data.length == 20,
          results: _.map(data, formatLocation)
        };
      },
      cache: true
    },
    initSelection: function(element, callback) {
        var id = $(element).val();
        if (id !== "") {
          $.ajax(gon.location_service_url + "/details", {
            dataType: 'json',
            data: { id: id, ancestors: true },
            success: function(data) {
              callback(formatLocation(data[0]));
            }
          });
        }
      }
  });
});
