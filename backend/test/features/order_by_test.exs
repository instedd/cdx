defmodule OrderByTest do
  use Cdp.TestCase
  import TestHelpers

  test "order by age" do
    post_event results: [result: "positive"], age: 20
    post_event results: [result: "negative"], age: 10

    response = get_updates("order_by=age")

    assert_all_values response, ["age", "results"], [
      [10, %{"result" => "negative"}],
      [20, %{"result" => "positive"}],
    ]
  end

  test "order by age desc" do
    post_event results: [result: "positive"], age: 10
    post_event results: [result: "negative"], age: 20

    response = get_updates("order_by=-age")

    assert_all_values response, ["age", "results"], [
      [20, %{"result" => "negative"}],
      [10, %{"result" => "positive"}],
    ]
  end

  test "order by age and gender" do
    post_event results: [result: "positive"], age: 20, gender: "male"
    post_event results: [result: "positive"], age: 10, gender: "male"
    post_event results: [result: "negative"], age: 10, gender: "female"
    post_event results: [result: "negative"], age: 20, gender: "female"

    response = get_updates("order_by=age,gender")

    assert_all_values response, ["age", "gender", "results"], [
      [10, "female", %{"result" => "negative"}],
      [10, "male", %{"result" => "positive"}],
      [20, "female", %{"result" => "negative"}],
      [20, "male", %{"result" => "positive"}],
    ]
  end

  test "order by age and gender desc" do
    post_event results: [result: "positive"], age: 20, gender: "male"
    post_event results: [result: "positive"], age: 10, gender: "male"
    post_event results: [result: "negative"], age: 10, gender: "female"
    post_event results: [result: "negative"], age: 20, gender: "female"

    response = get_updates("order_by=age,-gender")

    assert_all_values response, ["age", "gender", "results"], [
      [10, "male", %{"result" => "positive"}],
      [10, "female", %{"result" => "negative"}],
      [20, "male", %{"result" => "positive"}],
      [20, "female", %{"result" => "negative"}],
    ]
  end
end
