Given /^that @last is named '(.*)'$/ do |name|
  instance_variable_set("@#{name}", @last)
end

Then /^I invoke the debugger$/ do
  require 'ruby-debug'; Debugger.start; Debugger.settings[:autoeval] = 1; Debugger.settings[:autolist] = 1; debugger
end
