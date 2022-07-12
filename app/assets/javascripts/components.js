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

$(document).on("change", "input[type=date]", function(){
  $(this).val() != '' ? $(this).addClass("filled") : $(this).removeClass("filled");
});
