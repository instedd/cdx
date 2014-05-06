defmodule GroupByTest do
  use Cdp.TestCase
  import TestHelpers

  test "groups by gender and assay_code" do
    post_result result: "positive", gender: "male", assay_code: "a"
    post_result result: "positive", gender: "male", assay_code: "a"
    post_result result: "positive", gender: "male", assay_code: "b"
    post_result result: "negative", gender: "female", assay_code: "a"
    post_result result: "negative", gender: "female", assay_code: "b"
    post_result result: "negative", gender: "female", assay_code: "b"

    response = get_updates("group_by=gender,assay_code")
    response = Enum.sort response, fn(r1, r2) ->
      if r1["gender"] == r2["gender"] do
        r1["assay_code"] < r2["assay_code"]
      else
        r1["gender"] < r2["gender"]
      end
    end

    assert_all_values response, ["gender", "assay_code", "count"], [
      ["female", "a", 1],
      ["female", "b", 2],
      ["male", "a", 2],
      ["male", "b", 1],
    ]
  end

  test "groups by gender, result and assay_code" do
    post_result result: "positive", gender: "male", assay_code: "a"
    post_result result: "negative", gender: "male", assay_code: "a"
    post_result result: "positive", gender: "male", assay_code: "b"
    post_result result: "negative", gender: "female", assay_code: "a"
    post_result result: "negative", gender: "female", assay_code: "b"
    post_result result: "negative", gender: "female", assay_code: "b"

    response = get_updates("group_by=gender,result,assay_code")
    response = Enum.sort response, fn(r1, r2) ->
      if r1["gender"] == r2["gender"] do
        if r1["result"] == r2["result"] do
          r1["assay_code"] < r2["assay_code"]
        else
          r1["result"] < r2["result"]
        end
      else
        r1["gender"] < r2["gender"]
      end
    end

    assert_all_values response, ["gender", "result", "assay_code", "count"], [
      ["female", "negative", "a", 1],
      ["female", "negative", "b", 2],
      ["male", "negative", "a", 1],
      ["male", "positive", "a", 1],
      ["male", "positive", "b", 1],
    ]
  end

  test "group by year(date)" do
    create_result [result: "positive"], {{2010,1,1},{12,0,0}}
    create_result [result: "positive"], {{2010,1,2},{12,0,0}}
    create_result [result: "positive"], {{2011,1,1},{12,0,0}}

    response = get_updates("group_by=#{escape("year(created_at)")}")
    response = Enum.sort response, fn(r1, r2) -> r1["created_at"] < r2["created_at"] end

    assert_all_values response, ["created_at", "count"], [
      ["2010", 2],
      ["2011", 1],
    ]
  end

  test "group by month(date)" do
    create_result [result: "positive"], {{2010,1,1},{12,0,0}}
    create_result [result: "positive"], {{2010,2,2},{12,0,0}}
    create_result [result: "positive"], {{2011,1,1},{12,0,0}}
    create_result [result: "positive"], {{2011,1,2},{12,0,0}}
    create_result [result: "positive"], {{2011,2,1},{12,0,0}}

    response = get_updates("group_by=#{escape("month(created_at)")}")
    response = Enum.sort response, fn(r1, r2) -> r1["created_at"] < r2["created_at"] end

    assert_all_values response, ["created_at", "count"], [
      ["2010-01", 1],
      ["2010-02", 1],
      ["2011-01", 2],
      ["2011-02", 1],
      ]
  end

  test "group by week(date)" do
    create_result [result: "positive"], {{2010,1,4},{12,0,0}}
    create_result [result: "positive"], {{2010,1,5},{12,0,0}}
    create_result [result: "positive"], {{2010,1,6},{12,0,0}}
    create_result [result: "positive"], {{2010,1,12},{12,0,0}}
    create_result [result: "positive"], {{2010,1,13},{12,0,0}}

    response = get_updates("group_by=#{escape("week(created_at)")}")
    response = Enum.sort response, fn(r1, r2) -> r1["created_at"] < r2["created_at"] end

    assert_all_values response, ["created_at", "count"], [
      ["2010-W1", 3],
      ["2010-W2", 2],
      ]
  end

  test "group by day(date)" do
    create_result [result: "positive"], {{2010,1,4},{12,0,0}}
    create_result [result: "positive"], {{2010,1,4},{13,0,0}}
    create_result [result: "positive"], {{2010,1,4},{14,0,0}}
    create_result [result: "positive"], {{2010,1,5},{12,0,0}}

    response = get_updates("group_by=#{escape("day(created_at)")}")
    response = Enum.sort response, fn(r1, r2) -> r1["created_at"] < r2["created_at"] end

    assert_all_values response, ["created_at", "count"], [
      ["2010-01-04", 3],
      ["2010-01-05", 1],
      ]
  end

  test "group by day(date) and result" do
    create_result [result: "positive"], {{2010,1,4},{12,0,0}}
    create_result [result: "positive"], {{2010,1,4},{13,0,0}}
    create_result [result: "negative"], {{2010,1,4},{14,0,0}}
    create_result [result: "positive"], {{2010,1,5},{12,0,0}}

    response = get_updates("group_by=#{escape("day(created_at)")},result")
    response = Enum.sort response, fn(r1, r2) ->
      if r1["created_at"] == r2["created_at"] do
        r1["result"] < r2["result"]
      else
        r1["created_at"] < r2["created_at"]
      end
    end

    assert_all_values response, ["created_at", "result", "count"], [
      ["2010-01-04", "negative", 1],
      ["2010-01-04", "positive", 2],
      ["2010-01-05", "positive", 1],
      ]
  end
end
