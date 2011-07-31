##
# Module for files being debugged
module SprayTabs
  
  ##
  # Sends and evaluates command with Spray REPL
  def self.send_to_repl(command)
    tab= SprayTabs.find_first_matching_tab('Spray: ')
    if tab.nil?
      raise "Spray, open a file and goto Plugins -> Spray -> Debug"
    else
      tab.edit_view.document.insert_at_cursor(command)
      tab.edit_view.document.mirror.evaluate(command)
    end
  end
  
  def self.set_current_tab(path, line)
    tab= (SprayTabs.find_first_matching_tab(path) || SprayTabs.open_tab(path))
    tab.focus
    tab.document.scroll_to_line(line)
  end
  
  ##
  # Returns nil when no matches
  def self.find_first_matching_tab(path)
    Redcar.app.focussed_window.all_tabs.select{|tab|
      ((tab.document.path rescue nil) =~ /#{path}/) or
      ((tab.document.title rescue nil) =~ /#{path}/)
    }.first
  end
  
  ##
  # Returns opened tab, or nil if file not exists
  def self.open_tab(path)
    if File.exist?(path)
      tab  = Redcar.app.focussed_window.new_tab(Redcar::EditTab)
      mirror = Redcar::Project::FileMirror.new(path)
      tab.edit_view.document.mirror = mirror
      tab.edit_view.reset_undo
      tab
    end
  end
  
  def self.scroll_to(path, line)
    tab= (SprayTabs.find_first_matching_tab(path) || SprayTabs.open_tab(path))
    tab.edit_view.document.scroll_to_line(line)
  end
  
  def self.focussed_doc
    Redcar.app.focussed_window.focussed_notebook_tab_document
  end
  
  def self.focussed_path; focussed_doc.path rescue nil; end
  
  def self.focussed_line; (focussed_doc.cursor_line+1) rescue nil; end
end