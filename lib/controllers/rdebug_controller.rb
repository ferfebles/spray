require 'net/telnet'

class RDebugController
  RDEBUG_NO_PRINT= File.expand_path(File.join(File.dirname(__FILE__), "rdebug_no_print.rb"))
  RDEBUG_PROMPT= /PROMPT \(rdb:\d*\) |CONFIRM Really quit\? \(y\/n\)/
  @@current_port= 31415
  @@s= nil
  
  attr_reader :command
  
  def initialize(path, host='localhost', port=nil)
    @path, @host, @port = path, host, (port || @@current_port+=1)
    @command= "rdebug --debug -nx -p #{@port} -s -w -r '#{RDEBUG_NO_PRINT}' '#{@path}'"
  end
  
  def connect
    retries= 1 #1 seconds of timeout
    begin
      @@s= Net::Telnet::new("Host"=> @host, "Port"=> @port, "Prompt"=> RDEBUG_PROMPT,
      "Telnetmode"=> false, "Timeout"=> 1, "Waittime"=> 0)
    rescue
      sleep 0.1
      retry if 0 <= (retries-=0.1)
      raise("Timeout connecting to rdebug on #{@host}:#{@port}")
    end
    @@s.waitfor(/PROMPT \(rdb:\d*\)/)
  end
  
  def execute_command(command)
    case command
    when /^\s*toggle_breakpoint/
      file, line= command.scan(/'(.*)':(\d+)/).first
      toggle_breakpoint(file ,line.to_i)
    else
      send_command(command)
    end
  end
  
  def toggle_breakpoint(filename, linenum)
    if current_breakpoints.include?([filename,linenum])
      breaknum= send_command("info break").scan(/(\d+).*#{filename.gsub('/','\/')}:#{linenum}/).first.first
      send_command("del #{breaknum}")
    else
      send_command("break #{filename}:#{linenum}")
    end
  end
  
  def current_breakpoints
    send_command("info break").scan(/(\/.*):(\d*)/).map{|file,line| [file,line.to_i]} rescue []
  end
  
  # Returns array with current position: [[file, line]]
  def current_position
    send_command("info line").scan(/Line\s(\d+).*"(.*)"/).map{|line,file| [file,line.to_i]} rescue []
  end
  
  def send_command(command)
    @@s.cmd(command) || ''
  end
  
end
