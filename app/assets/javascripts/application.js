// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/sstephenson/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require jquery.turbolinks
//= require jquery_ujs
//= require jquery.are-you-sure
//= require lodash
//= require select2
//= require react
//= require react_ujs
//= require classnames
//= require react-input-autosize
//= require react-select
//= require components
//= require d3
//= require_tree .

function cdx_init_components(dom) {
  ReactRailsUJS.mountComponents(dom);
}

$(document).ready(function(){
  function setFilledClass(elem) {
    window.setTimeout(function(){
      if(elem.val().length > 0) {
          elem.addClass('filled');
      } else {
          elem.removeClass('filled');
      }
    }, 0);
  }

  $("input[type='email'], input[type='password']")
    .on('keydown', function() {
      setFilledClass($(this));
    })
    .each(function() {
      setFilledClass($(this));
    });

  $(document).on('click', '.row-href tr[data-href]', function(){
    window.location.href = $(this).data('href');
  });

  $('form[data-auto-submit]').each(function(){
    var form = $(this);
    var payload = form.serialize();

    var debouncedSubmit = _.debounce(function(){
      form.submit();
    }, 2000);

    form.on('change', function(){
      if (payload != form.serialize()) {
        payload = form.serialize()
        debouncedSubmit();
      }
    });
  });

  $(document).on('click', '.tabs .tabs-header a:not(".selected")', function(event) {
    var target = $(event.target);
    var tabsHeader = target.closest('ul');
    $('a', tabsHeader).removeClass('selected');
    target.addClass('selected');
    var tabsContents = target.closest('.tabs').children('.tabs-content');
    tabsContents.removeClass('selected');
    var selectedDiv = tabsContents.eq(target.closest('li').index());
    selectedDiv.addClass('selected');
    if(!selectedDiv.hasClass('loaded')) {
      selectedDiv.addClass('loaded');
      $.get(target.attr('href'), function(data) {
        selectedDiv.html(data);
        cdx_init_components(selectedDiv);
      });
    }
  });

  $(document).on('click', '.tabs .tabs-header a', function(event) {
    event.preventDefault();
  });

  $(".tabs .tabs-header li:first-child a").trigger('click');

  /* Initialize sticky outside the event listener as a cached selector.
   * Also, initialize any needed variables outside the listener for
   * performance reasons - no variable instantiation is happening inside the listener.
   */
  var sticky = $('.fix');
  if (sticky.length > 0) {
    var stickyTop = sticky.offset().top - 30,
        scrollTop,
        scrolled = false,
        $window = $(window);

    /* Bind the scroll Event */
    $window.on('scroll', function (e) {
        scrollTop = $window.scrollTop();

        if (scrollTop >= stickyTop) {
            sticky.addClass('fixed');
        } else if (scrollTop < stickyTop) {
            sticky.removeClass('fixed');
        }
    });
  }

  $(".institution-radio label").on('click', function() {
      $(".institution-container").addClass('active');
      position = $(window).scrollTop()
      if (position < 180) {
        $('html,body').animate({
          scrollTop: position + (180 - position)
        });
      } else {
        $('html,body').animate({
          scrollTop: position - (position - 180)
        });
      }
  });

  $(".btn-toggle").click(function(){
    $(".advanced").toggleClass('show');
    $(this).toggleClass('up');
    return false;
  });

});

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
