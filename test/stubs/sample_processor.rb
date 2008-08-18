class SampleProcessor < ActiveMessaging::BaseProcessor  
  def on_message( message )
    logger.info "#{self.class.name} just processed the following message:\n\n#{message}\n\n"    
  end
end
