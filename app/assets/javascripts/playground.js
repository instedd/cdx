$(function() {
  if ($("#playground").length > 0){
    $report_form = $("#report_form");
    $create_button = $("#create_button");
    $report_form.submit(function() {
      $create_button.prop("disabled", true);
      $create_button.val("Creating...");
      device = $("#device").val();
      data = $("#data").val();
      $.ajax({
        url: "/api/devices/" + device + "/events",
        type: "POST",
        data: data,
        contentType: "application/json; charset=utf-8",
        success: function(data, textStatus, jqXHR) {
          $create_button.prop("disabled", false);
          $create_button.val("Created!");
          setTimeout(function() { $create_button.val("Create another event"); }, 1000);
        },
        error: function(jqXHR, textStatus, errorThrown) {
          $create_button.prop("disabled", false);
          $create_button.val("Error: " + errorThrown);
          setTimeout(function() { $create_button.val("Create another event"); }, 1000);
        }
      });
      return false;
    });

    $query_form = $("#query_form");
    $query_button = $("#query_button");
    $query_form.submit(function() {
      query_string = $("#query_string").val();
      post_body = $("#post_body").val();
      $query_button.prop("disabled", true);
      $query_button.val("Querying...");

      $.ajax({
        url: "/api/events?" + query_string,
        type: "POST",
        data: post_body,
        contentType: "application/json; charset=utf-8",
        success: function(data, textStatus, jqXHR) {
          $query_button.prop("disabled", false);
          $query_button.val("Query");
          data = JSON.stringify(data, null, 4);
          $("#response_div").show();
          $("#response").text(data);
        },
        error: function(jqXHR, textStatus, errorThrown) {
          $query_button.prop("disabled", false);
          $query_button.val("Error: " + errorThrown);
          setTimeout(function() { $query_button.val("Query"); }, 1000);
        }
      });

      return false;
    });
  }

});
