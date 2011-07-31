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
        "#{e.class}: #{e.message}" #\n        '#{backtrace.join("'\n        '")}'"
      end
      
      class SprayEvaluator
        def initialize(path)
          @binding   = binding
          @path      = path
          @controller= case File.extname(path)
          when '.rb'   then RDebugController.new(path)
          when '.java' then raise("Java support still not implemented")
          else raise("Spray can't handle this file type")
          end
          @annotations= Hash.new{|h,k| h[k]= Array.new}
          Redcar::Runnables.run_process(File.dirname(path), @controller.command, "SprayOutput")
        end
        
        def inspect; "SprayEvaluator"; end
        
        def toggle_breakpoint(filename, linenum)
          @controller.toggle_breakpoint(filename, linenum)
        end
        
        def execute(command)
          begin
            @controller.send_command(command)
          rescue
            @controller.connect; retry
          ensure
            update_annotations(@controller.current_position, Annotations::CURRENT_LINE)
            update_annotations(@controller.current_breakpoints, Annotations::BREAKPOINT)
          end
        end
        
        def update_annotations(current_positions, type)
          if @annotations[type] != current_positions
            @annotations[type].each{|position| Annotations.remove(position, type)}
            @annotations[type]= current_positions
            @annotations[type].each{|position| Annotations.set(position, type)}
          end
        end
      end
      
    end
  end
end
