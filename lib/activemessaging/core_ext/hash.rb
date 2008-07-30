%w( keys ).each do |ext|
  require "activemessaging/core_ext/hash/#{ext}"  
end

class Hash #:nodoc:
  include ActiveMessaging::CoreExtensions::Hash::Keys
end
