def alert_form_fillin_basic(form, arg)
  form.name.set arg
  form.description.set 'aaaaa'
  form.message.set 'web msg'
  form.smsmessage.set 'sms msg'
  form.smslimit.set 2
  form.emaillimit.set 2
end

def alert_form_fillin_externaluser(form)
  form.externaluser_firstname.set 'bob'
  form.externaluser_lastname.set 'smith'
  form.externaluser_email.set 'aa@bb.com'
  form.externaluser_telephone.set '1234567'
end
