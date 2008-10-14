namespace :test do
  
  desc 'Sort the log file by time'
  task :fixlog do
    
    # read the file placing any entries which are out of time sequence
    # into the correct order.
    h = {}
    last_insert = '['    
    open('test/test.log', 'r') do |f|
      f.each_line do |line|
        if line[0..0] == '['
          t = line.split.first
          unless t.nil?
            last_insert = t
            h[t] ||= []
            h[t] << line
          end
        else
          h[last_insert] ||= []
          h[last_insert] << line
        end  
      end
    end
    
    # remove seconds from time values
    h.each_pair do |k,lines|      
      lines.each{|line| line.gsub!( /(^\[.{8}\.\d{6})/ ){ $1.chop.chop }}
    end
    
    # replace thread id numbers with easier ones to read.
    
    # collect names of all threads and setup conversion
    thread_list = {}    
    h.keys.sort.each do |k|
      h[k].each do |line|
        if line =~ /Thread\:(\s*\d*)/
          thread_list.store( $1, "%03d" % (thread_list.size + 1)) unless
          thread_list[ $1 ]          
        end
      end
    end
    
    # iterate through all lines converting threads to easier to read ids.  
    h.each_pair do |k,lines|
      lines.each do |line|
        thread_list.each_pair do |old, new|
          line.gsub!( old, new )
        end
      end
    end
    
    # write out the file
    open('test/test.log', 'w') do |f|
      h.keys.map{|k| k.to_s}.sort.each do |k|
        h[k].each{|line| f.print(line)}
      end
    end
  
    puts "Completed test log clean-up."
  end # task
  
end