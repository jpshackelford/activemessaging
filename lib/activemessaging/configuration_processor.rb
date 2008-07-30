module ActiveMessaging
  class ConfigurationProcessor < BaseProcessor
    
    def on_message(message)
      LOG.debug "Received configuration message."
      ActiveMessaging::System.configure do |my|
        my.configuration( YAML.load(message) )
      end
      LOG.debug "Completed configuration."
    end
    
  end
end