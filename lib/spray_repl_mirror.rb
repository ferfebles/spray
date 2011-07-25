require 'controllers/rdebug_controller'
require 'annotations'

module Redcar
  class Spray
    class SprayReplMirror < Redcar::REPL::ReplMirror
      
      attr_reader :title, :prompt, :grammar_name, :evaluator
      
      def initialize
        @spray_path  = Redcar.app.focussed_window.focussed_notebook_tab_document.path
        raise "No file, please select another tab" if @spray_path.nil?
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
          @controller= case File.extname(path)
          when '.rb'   then RDebugController.new(path)
          when '.java' then raise("Java support still not implemented")
          else raise("Spray can't handle this file type")
          end
          @previous_file, @previous_line = path, 1
          Redcar::Runnables.run_process(File.dirname(path), @controller.command, "SprayOutput")
        end
        
        def inspect; "SprayEvaluator"; end
        
        def execute(command)
          begin
            retries=1
            Annotations.remove(@previous_file, @previous_line)
            output= @controller.send_command(command)
            @current_line, @current_file= @controller.current_position
            Annotations.set(@current_file, @current_line)
            @previous_file, @previous_line = @current_file, @current_line
            return output
          rescue
            (@controller.connect; retry) if 0 <= (retries-=1)
          end
        end
      end
      
    end
  end
end
