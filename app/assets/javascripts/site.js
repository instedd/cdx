$(function() {
  // Only run on site forms
  if ($('form.edit_site, form.new_site').length == 0) return;

  var map = L.map('map').setView([0, 0], 2);
  L.tileLayer('http://{s}.tile.osm.org/{z}/{x}/{y}.png', {
    attribution: '&copy; <a href="http://osm.org/copyright">OpenStreetMap</a> contributors'
  }).addTo(map);
  L.Control.geocoder().addTo(map);
});
