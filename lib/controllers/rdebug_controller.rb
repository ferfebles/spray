require 'net/telnet'

class RDebugController
  RDEBUG_NO_PRINT= File.expand_path(File.join(File.dirname(__FILE__), "rdebug_no_print.rb"))
  PROMPT= {:rdebug=> /PROMPT \(rdb:\d*\) |CONFIRM Really quit\? \(y\/n\)/, :control=> /PROMPT \(rdb:ctrl\)/}
  @@current_port= 31415
  
  attr_reader :launch_debugger_command
  
  def initialize(path, host='127.0.0.1', port=nil)
    @connected, @remote= false, {:rdebug=> nil, :control=> nil}
    @path, @host, @port = path, host, {:rdebug=> (port || @@current_port+=2)}
    @port[:control]= @port[:rdebug]+1
    @launch_debugger_command= "rdebug -nx -p #{@port[:rdebug]} --cport #{@port[:control]} -s -w -r '#{RDEBUG_NO_PRINT}' '#{@path}'"
  end
  
  def connect(remote_port=:rdebug)
    retries= 10
    begin
      @remote[remote_port]= Net::Telnet::new("Host"=> @host, "Port"=> @port[remote_port],
      "Prompt"=> PROMPT[remote_port], "Telnetmode"=> false, "Timeout"=> 1, "Waittime"=> 0)
    rescue
      (sleep 0.1; retry) if 0<=(retries-=1)
      @connected= false
      raise("Timeout connecting to rdebug on #{@host}:#{@port[remote_port]}")
    end
    @remote[remote_port].waitfor(PROMPT[remote_port])
    @connected= true
  end
  
  def execute_command(command)
    case command
    when /^\s*toggle_breakpoint/
      file, line= command.scan(/'(.*)':(\d+)/).first
      toggle_breakpoint(file ,line.to_i)
    when /^\s*interrupt/
      send_command(command, :control)
    else
      send_command(command)
    end
  end
  
  def toggle_breakpoint(filename, linenum)
    if current_breakpoints.include?([filename,linenum])
      breaknum= send_command("info break").scan(/(\d+).*#{filename.gsub('/','\/')}:#{linenum}/).first.first
      send_command("del #{breaknum}")
    else
      send_command("break #{filename}:#{linenum}") #TODO problem with c:\ on windows
    end
  end
  
  def current_breakpoints
    send_command("info break").scan(/(\/.*):(\d*)/).map{|file,line| [file,line.to_i]} rescue []
  end
  
  # Returns array with current position: [[file, line]]
  def current_position
    send_command("info line").scan(/Line\s(\d+).*"(.*)"/).map{|line,file| [file,line.to_i]} rescue []
  end
  
  def connected?
    @connected
  end
  
  def send_command(command, remote_port=:rdebug)
    begin
      @remote[remote_port].cmd(command) || ''
    rescue
      connect(remote_port); retry
    end
  end
  
end
