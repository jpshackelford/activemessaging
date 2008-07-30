module ActiveMessaging  

  TEST_DIR = File.expand_path( File.dirname(__FILE__) + '/../')
  LIB_DIR  = File.expand_path( File.join(TEST_DIR, %w[.. lib]))
  
  class << self
  
    def path(dir,*args)
      p = [dir]
      p += args
      File.expand_path(File.join(*p))  
    end
    
    def lib_path(*args)
      path(LIB_DIR,*args)
    end
    
    def test_path(*args)
      path(TEST_DIR,*args)
    end
    
  end
  
end

# Add the testing directory to the load path
$LOAD_PATH.unshift( ActiveMessaging::TEST_DIR )
