//= require_tree ./components

function cdx_select_selector(name) {
  return ".Select :hidden[name='" + name + "']"
}

function cdx_select_find(name) {
  return $(cdx_select_selector(name));
}

function cdx_select_value(name) {
  return cdx_select_find(name).val();
}

function cdx_select_on_change(name, callback) {
  $(document).on('change', cdx_select_selector(name), function(){
    callback($(this).val());
  });
}

/*
This is kind of a exception solution. Because input date's behavior are different.
Consider this points:
  - input date's placeholders doesn't work
  - even if at some point in the future it works, you cannot know what's the OS date format
  - CSS selectors like :empty, :valid, [value=''], :placeholder-shown doesn't work
  - date format's depends of the browser and OS
  - Google Chrome has specific selector to color the content of this kind of fields, but other browser doesn't

  Finally you can test if something changes on the future on this fiddle:
    https://jsfiddle.net/omelao/hsk8vyax/15/
*/
$(document).on("change", "input[type=date]", function(){
  $(this).val() != '' ? $(this).addClass("filled") : $(this).removeClass("filled");
});
$(function(){
  $("input[type=date]").change();
});
