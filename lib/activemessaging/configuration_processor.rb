module ActiveMessaging
  class ConfigurationProcessor < BaseProcessor
    
    def on_message(message)
      LOG.debug "Received configuration message."

      config = YAML.load( message )
     
      unless config.respond_to? :[]
        raise BadConfigurationException, "YAML message expected to contain "+
          "a hash but did not. Fix #{config_file} and try again."        
      end
      
      ActiveMessaging::System.configure do |my|
        my.configuration( config.symbolize_keys!(:deep) )
      end
      
      LOG.debug "Completed configuration."
    end
    
  end
end