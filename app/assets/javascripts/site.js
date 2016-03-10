$(function() {
  // Only run on site forms
  if ($('form.edit_site, form.new_site').length == 0) return;

  $('form').on('keydown', function(evt) {
    if(evt.keyCode == 13 && evt.target.name == 'site[address]') {
      evt.preventDefault();
    }
  });
});
