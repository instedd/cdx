include Policy::Actions

def assert_can(user, resource, action, expected_result = [resource])
  result = Policy.can? action, resource, user

  result.should be_true

  result = Policy.authorize action, resource, user
  result = result.sort_by &:id
  expected_result = expected_result.sort_by &:id

  result.should eq(expected_result)
end

def assert_cannot(user, resource, action)
  result = Policy.cannot? action, resource, user
  result.should be_true
end

def grant(granter, user, resource, action, delegable = true)
  grant_or_deny granter, user, resource, action, delegable, "allow"
end

def deny(granter, user, resource, action, delegable = true)
  grant_or_deny granter, user, resource, action, delegable, "deny"
end

def grant_or_deny(granter, user, resource, action, delegable, effect)
  policy = Policy.make_unsaved
  policy.definition = policy_definition(resource, action, delegable, effect)
  policy.granter_id = granter.id
  policy.user_id = user.id
  policy.save!
  policy
end

def policy_definition(resource, action, delegable = true, effect = "allow")
  resource = Array(resource).map(&:resource_name)
  action = Array(action)

  JSON.parse %(
    {
      "statement":  [
        {
          "effect": "#{effect}",
          "action": #{action.to_json},
          "resource": #{resource.to_json}
        }
      ],
      "delegable": #{delegable}
    }
  )
end
