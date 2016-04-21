$.rails.allowAction = function(link){
  if (link.data("confirm") == undefined){
    return true;
  }
  $.rails.showConfirmationDialog(link);
  return false;
}

var reactConfirmationModalConfirmationAction = null;

$.rails.showConfirmationDialog = function(link){
  var message = link.data("confirm");
  var title = link.data("confirm-title");
  var hideCancel = link.data("confirm-hide-cancel");
  var confirmButtonMessage = link.data('confirm-button-message');
  var confirmationModalContainer = $('#confirmationModalContainer')
  if(confirmationModalContainer.length == 0) {
    confirmationModalContainer = $('<div id="confirmationModalContainer">');
    $("body").append(confirmationModalContainer);
  } else {
    confirmationModalContainer.empty();
  }

  reactConfirmationModalConfirmationAction = function() {
    var confirm_data = link.attr('data-confirm');

    // `link.data` is a JS object that's not related with the DOM
    // We need to null link.data for link.trigger to work, and
    // removeAttr for link.is to not match
    link.data('confirm', null);
    link.removeAttr('data-confirm');

    if(link.is($.rails.linkClickSelector)) {
      link.trigger('click.rails');
    } else {
      link[0].click();
    }

    // restore the link in case we don't leave the page
    link.data('confirm', confirm_data);
    link.attr('data-confirm', confirm_data);
  }

  confirmationModalContainer.append($("<div>")
    .attr('data-react-class', 'ConfirmationModal')
    .attr('data-react-props', JSON.stringify({message: message, title: title, target: 'reactConfirmationModalConfirmationAction', deletion: link.data('method') == 'delete', hideCancel: hideCancel, confirmMessage: confirmButtonMessage })));
  cdx_init_components(confirmationModalContainer);
}
