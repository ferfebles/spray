require 'net/telnet'

class RDebugController
  RDEBUG_NO_PRINT= File.expand_path(File.join(File.dirname(__FILE__), "rdebug_no_print.rb"))
  RDEBUG_PROMPT= /PROMPT \(rdb:\d*\) |CONFIRM Really quit\? \(y\/n\)/
  @@current_port= 31415
  
  attr_reader :launch_debugger_command
  
  def initialize(path, host='127.0.0.1', port=nil)
    @connected, @remote_debug, @remote_control= false, nil, nil
    @path, @host, @port = path, host, (port || @@current_port+=2)
    @launch_debugger_command= "rdebug -nx -p #{@port} --cport #{@port+1} -s -w -r '#{RDEBUG_NO_PRINT}' '#{@path}'"
  end
  
  def connect
    retries= 1 #1 seconds of timeout
    begin
      @remote_debug= Net::Telnet::new("Host"=> @host, "Port"=> @port, "Prompt"=> RDEBUG_PROMPT,
      "Telnetmode"=> false, "Timeout"=> 1, "Waittime"=> 0)
    rescue
      (sleep 0.1; retry) if 0<=(retries-=0.1)
      @connected= false
      raise("Timeout connecting to rdebug on #{@host}:#{@port}")
    end
    @remote_debug.waitfor(/PROMPT \(rdb:\d*\)/)
    @connected= true
  end
  
  def connect_control
    retries= 10 #1 seconds of timeout
    begin
      @remote_control= Net::Telnet::new("Host"=> @host, "Port"=> @port+1, "Prompt"=> /PROMPT \(rdb:ctrl\)/,
      "Telnetmode"=> false, "Timeout"=> 10, "Waittime"=> 1)
    rescue
      (sleep 1; retry) if 0<=(retries-=1)
      raise("Timeout connecting to rdebug control on #{@host}:#{@port+1}")
    end
    @remote_control.waitfor(/PROMPT \(rdb:ctrl\)/)
  end
  
  def execute_command(command)
    case command
    when /^\s*toggle_breakpoint/
      file, line= command.scan(/'(.*)':(\d+)/).first
      toggle_breakpoint(file ,line.to_i)
    when /^\s*interrupt/
      puts "before interrupt"
      control_interrupt
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
  
  def control_interrupt
    begin
      puts "interrupt"
      @remote_control.cmd('interrupt') || ''
    rescue
      connect_control; retry
    end
  end
  
  def current_breakpoints
    #if connected?
      send_command("info break").scan(/(\/.*):(\d*)/).map{|file,line| [file,line.to_i]} rescue []
      #else
      #[]
      #end
  end
  
  # Returns array with current position: [[file, line]]
  def current_position
    #    if connected?
      send_command("info line").scan(/Line\s(\d+).*"(.*)"/).map{|line,file| [file,line.to_i]} rescue []
      #else
      #[]
      #end
  end
  
  def connected?
    @connected
  end
  
  def send_command(command)
    begin
      puts command
      @remote_debug.cmd(command) || ''
    rescue
      connect; retry
    end
  end
  
end
