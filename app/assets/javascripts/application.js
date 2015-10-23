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

$(document).ready(function(){
  $('.ddown').ddslick();

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
        ReactRailsUJS.mountComponents(selectedDiv);
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

});
