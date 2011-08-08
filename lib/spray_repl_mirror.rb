require 'controllers/rdebug_controller'
require 'annotations'

module Redcar
  class Spray
    class SprayReplMirror < Redcar::REPL::ReplMirror
      
      attr_reader :title, :prompt, :grammar_name, :evaluator
      
      def initialize
        @spray_path  = Redcar.app.focussed_window.focussed_notebook_tab_document.path
        raise "No file to debug, please select another tab" if @spray_path.nil?
        @evaluator   = SprayEvaluator.new(@spray_path)
        @title = "Spray: #{File.basename(@spray_path)}"
        @prompt= "(#{File.extname(@spray_path)})>"
        @grammar_name= "Spray REPL"
        super
      end
      
      def format_error(e)
        backtrace= e.backtrace.reject{|l| l=~ /repl_mirror/}
        backtrace.unshift("(repl):1")
        "#{e.class}: #{e.message}" #\n        ##{backtrace.join("\n        #")}"
      end
      
      class SprayEvaluator
        def initialize(path)
          @binding   = binding
          @controller= case File.extname(path)
          when '.rb'   then RDebugController.new(path)
          when '.java' then raise("Java support still not implemented")
          else raise("Spray can't handle this file type")
          end
          @annotations= Redcar::Plugin::Storage.new("SprayAnnotations")
          @annotations[Annotations::CURRENT_LINE]=[[path,1]]
          @annotations.set_default(Annotations::BREAKPOINT,[])
          Redcar::Runnables.run_process(File.dirname(path), @controller.launch_debugger_command, "SprayOutput")
        end
        
        def inspect; "SprayEvaluator"; end
        
        def execute(command)
          begin
            init_needed=true unless @controller.connected?
            @controller.execute_command(command)
          ensure
            initialize_breakpoints if (init_needed and @controller.connected?)
            update_annotations(@controller.current_position, Annotations::CURRENT_LINE)
            update_annotations(@controller.current_breakpoints, Annotations::BREAKPOINT)
          end
        end
        
        def initialize_breakpoints
          @annotations[Annotations::BREAKPOINT].each{|file, line| 
            @controller.execute_command("toggle_breakpoint '#{file}':#{line}")}
          @annotations[Annotations::BREAKPOINT]=[]
        end
        
        def update_annotations(current_positions, type)
          if @annotations[type] != current_positions
            @annotations[type].each{|position| Annotations.remove(position, type)}
            current_positions.each{|position| Annotations.set(position, type)}
            @annotations[type]= current_positions if @controller.connected?
          end
        end
      end
      
    end
  end
end
