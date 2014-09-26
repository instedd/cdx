  $(function() {
    if ($("#simulator").length > 0) {
      populate_fields();

      $("#device").change(function() {
        $("#result")
          .find('option')
          .remove()
          .end()
        ;
        $("#condition")
          .find('option')
          .remove()
          .end()
        ;
        $("#gender")
          .find('option')
          .remove()
          .end()
        ;

        populate_fields();
      });

      $report_form = $("#report_form");
      $create_button = $("#create_button");
      $report_form.submit(function() {
        device = $("#device").val();
        result= $("#result").val();
        condition= $("#condition").val();
        patient_name = $("#patient_name").val();
        patient_telephone_number = $("#patient_telephone_number").val();
        assay_name = result_and_condition["assay_name"][device]["original"][0];
        gender = $("#gender").val();
        age = $("#age").val();

        $create_button.prop("disabled", true);
        $create_button.val("Creating...");

        var data = '{"assay_name" : "' + assay_name + '", "test_type" : "specimen", "results" : [{"condition" : "' + condition + '" , "result" : "' + result + '"} ], "gender" : "' + gender + '" , "age" : ' + age + ' , "patient_name" : "' + patient_name + '" , "patient_telephone_number" : "' + patient_telephone_number +'"}';
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

function populate_field(field) {
  var device = $("#device").val();
  var select = document.getElementById(field);
  var options = result_and_condition[field][device]["original"];
  var titleized_options = result_and_condition[field][device]["titleized"];
  for(var i=0 ; i < options.length; i++) {
    var opt = options[i];
    var titleized_opt = titleized_options[i];
    var el = document.createElement("option");
    el.textContent = titleized_opt;
    el.value = opt;
    select.appendChild(el);
  }
}

function populate_fields(){
  populate_field("result");
  populate_field("condition");
  populate_field("gender");
}
