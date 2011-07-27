require 'spray_tabs'

module Annotations

  BREAKPOINT   = ["breakpoint.annotation.type","control-pause-small",[100, 100, 200]]
  CURRENT_LINE = ["current_line.annotation.type","control",[100, 100, 200]]

  def self.set(position, type=CURRENT_LINE)
    path, line = position
    tab= (SprayTabs.find_first_matching_tab(path) || SprayTabs.open_tab(path))
    unless Annotations.get_types(path).andand.include?(type)
      tab.edit_view.add_annotation_type(*type)
    end
    unless Annotations.get_lines(path, type).include?(line)
      tab.edit_view.add_annotation(type[0], line-1, type[0].split('.')[0], 0,0)
    end
    SprayTabs.set_current_tab(path, line)
  end

  def self.remove(position, type=CURRENT_LINE)
    path, line = position
    tab= (SprayTabs.find_first_matching_tab(path) || SprayTabs.open_tab(path))
    tab.edit_view.remove_annotation(Annotations.get(position, type))
  end

  def self.get(position, type=CURRENT_LINE)
    path, line = position
    tab= SprayTabs.find_first_matching_tab(path)
    begin
      annotation= tab.edit_view.annotations.find{|a| 
        (a.getLine==line-1) and (a.getType==type[0])
      }
    rescue 
      nil
    end
  end
  
  def self.get_types(path)
    tab= SprayTabs.find_first_matching_tab(path)
    tab.edit_view.annotations.map{|a| a.getType}.uniq! rescue []
  end
  
  def self.get_lines(path, type=CURRENT_LINE)
    tab= SprayTabs.find_first_matching_tab(path)
    begin
      annotations= tab.edit_view.annotations.select{|a| a.getType==type[0]}
      annotations.map{|a| a.getLine+1}.sort! 
    rescue 
      []
    end
  end
  
end
