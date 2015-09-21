include Policy::Actions

def assert_can(user, resource, action, expected_result = [resource])
  result = Policy.can? action, resource, user

  expect(result).to eq(true)

  result = Policy.authorize action, resource, user
  result = result.sort_by &:id
  expected_result = expected_result.sort_by &:id

  expect(result).to eq(expected_result)
end

def assert_cannot(user, resource, action)
  result = Policy.cannot? action, resource, user
  expect(result).to eq(true)
end

def grant(granter, user, resource, action, opts = {})
  policy = Policy.make_unsaved
  policy.definition = policy_definition(resource, action, opts.fetch(:delegable, true), opts.fetch(:except, []))
  policy.granter_id = granter.try(:id)
  policy.user_id = user.id
  policy.allows_implicit = true
  policy.save!
  policy
end

def policy_definition(resource, action, delegable = true, except = [])
  resource = Array(resource).map{|r| r.kind_of?(String) ? r : r.resource_name}
  except = Array(except).map{|r| r.kind_of?(String) ? r : r.resource_name}
  action = Array(action)

  JSON.parse %(
    {
      "statement":  [
        {
          "action": #{action.to_json},
          "resource": #{resource.to_json},
          "except": #{except.to_json},
          "effect": "allow"
        }
      ],
      "delegable": #{delegable}
    }
  )
end
