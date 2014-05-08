defmodule OrderByTest do
  use Cdp.TestCase
  import TestHelpers

  test "order by age" do
    post_result result: "positive", age: 20
    post_result result: "negative", age: 10

    response = get_updates("order_by=age")

    assert_all_values response, ["age", "result"], [
      [10, "negative"],
      [20, "positive"],
    ]
  end

  test "order by age desc" do
    post_result result: "positive", age: 10
    post_result result: "negative", age: 20

    response = get_updates("order_by=-age")

    assert_all_values response, ["age", "result"], [
      [20, "negative"],
      [10, "positive"],
    ]
  end

  test "order by age and gender" do
    post_result result: "positive", age: 20, gender: "male"
    post_result result: "positive", age: 10, gender: "male"
    post_result result: "negative", age: 10, gender: "female"
    post_result result: "negative", age: 20, gender: "female"

    response = get_updates("order_by=age,gender")

    assert_all_values response, ["age", "gender", "result"], [
      [10, "female", "negative"],
      [10, "male", "positive"],
      [20, "female", "negative"],
      [20, "male", "positive"],
    ]
  end

  test "order by age and gender desc" do
    post_result result: "positive", age: 20, gender: "male"
    post_result result: "positive", age: 10, gender: "male"
    post_result result: "negative", age: 10, gender: "female"
    post_result result: "negative", age: 20, gender: "female"

    response = get_updates("order_by=age,-gender")

    assert_all_values response, ["age", "gender", "result"], [
      [10, "male", "positive"],
      [10, "female", "negative"],
      [20, "male", "positive"],
      [20, "female", "negative"],
    ]
  end
end
