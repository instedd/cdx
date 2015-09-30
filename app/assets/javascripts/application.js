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
//= require underscore
//= require select2
//= require react
//= require react_ujs
//= require components
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


  /* Initialize sticky outside the event listener as a cached selector.
   * Also, initialize any needed variables outside the listener for
   * performance reasons - no variable instantiation is happening inside the listener.
   */
  var sticky = $('.fix'),
      stickyTop = sticky.offset().top - 30,
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

});
