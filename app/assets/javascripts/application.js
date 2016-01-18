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
//= require urijs
//= require lodash
//= require leaflet
//= require leaflet-control-geocoder
//= require classnames
//= require react
//= require react_ujs
//= require react-dom
//= require react-autosuggest
//= require react-input-autosize
//= require react-select
//= require react-leaflet
//= require components
//= require d3
//= require_tree .
//= require turbolinks
Turbolinks.enableProgressBar()

// Configure leaflet
L.Icon.Default.imagePath = '/assets'

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
    Turbolinks.visit($(this).data('href'));
  });

  $('form[data-auto-submit]').each(function(){
    var form = $(this);
    var payload = form.serialize();

    var debouncedSubmit = _.debounce(function(){
      var options = {};
      var action = form.attr('action') || window.location.href;
      var url = action + (action.indexOf('?') === -1 ? '?' : '&') + form.serialize();
      Turbolinks.visit(url.toString(), options);
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

  var advancedTimeout = null;
  $(".btn-toggle").click(function(){

    // We want to set overflow visible after the expand animation has completed
    var advanced = $(".advanced");
    if (advanced.hasClass('show')) {
      if (advancedTimeout) window.clearTimeout(advancedTimeout);
      advanced.css('overflow', 'hidden');
    } else {
      advancedTimeout = window.setTimeout(function() { advanced.css('overflow', 'visible'); }, 500);
    }

    advanced.toggleClass('show');
    $(this).toggleClass('up');
    return false;
  });


  var flashn = $(".flash.flash_notice");

  flashn.append( "<a class='close-notification'>x</a>" );

  flashn.delay(3000).fadeOut(300);

  $(".close-notification").click(function(){
    flashn.hide();
  });



  $(".clear-label").on('click', function () {
    $(this).closest('.file-uploaded').addClass('remove');
  });



  // Drag Picture to an input file and preview it
  if(document.getElementById('device_model_picture')) {
    var imageLoader = document.getElementById('device_model_picture');
        imageLoader.addEventListener('change', handleImage, false);

    function handleImage(e) {
        var reader = new FileReader();
        reader.onload = function (event) {

            $('.upload-new-file img').attr('src',event.target.result);
        }
        reader.readAsDataURL(e.target.files[0]);
    }


    // Change the class on the target zone when dragging a file over it

    document.addEventListener("dragenter", function( event ) {
      if ( event.target.className == "upload-picture" ) {
          $('.choose-picture').addClass('on');
      }

    }, false);

    document.addEventListener("dragleave", function( event ) {
      if ( event.target.className == "upload-picture" ) {
          $('.choose-picture').removeClass('on');
      }
    }, false);
  }


});


