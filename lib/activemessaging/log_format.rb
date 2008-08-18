module ActiveMessaging
  
  class LogFormat < ::Logger::Formatter        
  
    silence_warnings do
      Format = "[%s Thread:%8d] %5s -- %s: %s\n"
    end
    
    def call(severity, time, progname, msg)
      display_time = time.strftime("%H:%M:%S.") << "%06d" % time.usec
      Format % [display_time, Thread.current.object_id, severity,  
      progname, msg2str(msg)]
    end        
  end
  
end  
