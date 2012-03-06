require 'spray_repl_mirror'
require 'spray_tabs'

module Redcar
  class Spray
    ICONS_DIRECTORY = Redcar.icons_directory

    def self.menus
      Menu::Builder.build do
        sub_menu "Plugins" do
          sub_menu "Spray", :priority => 139 do
            item "Debug file", OpenSprayREPL
            ["List", "Step", "Next", "Continue"].each{|command|
              item(command) {Redcar.safely{SprayTabs.send_to_repl(command.downcase)}}
            }
          end
        end
      end
    end
    
    def self.toolbars
      ToolBar::Builder.build do
        item "Debug file", {:icon=>File.join(ICONS_DIRECTORY, "arrow-step-over.png"), :command=>OpenSprayREPL}
        item "Breakpoint", {:icon=>File.join(ICONS_DIRECTORY, "control-pause.png"), :command=>SprayToggleBreakpoint}
        item "Continue", {:icon=>File.join(ICONS_DIRECTORY, "arrow-step.png"), :command=>SpraySendContinue}
        item "Interrupt", {:icon=>File.join(ICONS_DIRECTORY, "control-stop-square.png"), :command=>SpraySendInterrupt}
        item "Next", {:icon=>File.join(ICONS_DIRECTORY, "arrow-270.png"), :command=>SpraySendNext}
        item "Step", {:icon=>File.join(ICONS_DIRECTORY, "arrow-315.png"), :command=>SpraySendStep}
        item "List", {:icon=>File.join(ICONS_DIRECTORY, "arrow-continue.png"), :command=>SpraySendList}
      end
    end
    
    class OpenSprayREPL < Redcar::REPL::OpenREPL
      def execute
        Redcar.safely{
          SprayTabs.find_first_matching_tab("SprayOutput").andand.close
          SprayTabs.find_first_matching_tab("Spray: ").andand.close
          open_repl(SprayReplMirror.new)
        }
      end
    end
    
    class SprayToggleBreakpoint < Redcar::Command
      def execute
        filename= SprayTabs.focussed_path
        linenum= SprayTabs.focussed_line
        Redcar.safely{SprayTabs.send_to_repl("toggle_breakpoint '#{filename}':#{linenum}")}
      end
    end

    class SpraySendList < Redcar::Command
      def execute; Redcar.safely{SprayTabs.send_to_repl("list")}; end
    end
    
    class SpraySendStep < Redcar::Command
      def execute; Redcar.safely{SprayTabs.send_to_repl("step")}; end
    end
    
    class SpraySendNext < Redcar::Command
      def execute; Redcar.safely{SprayTabs.send_to_repl("next")}; end
    end
    
    class SpraySendContinue < Redcar::Command
      def execute; Redcar.safely{SprayTabs.send_to_repl("continue")}; end
    end

    class SpraySendInterrupt < Redcar::Command
      def execute; Redcar.safely{SprayTabs.send_to_repl("interrupt")}; end
    end
    
  end
end

