# Given a filepath as a string, we resolve to a file in the workspace, grab it's project and then grab the relevant index for that project
# Return nil if the file is outside the workspace
CoreStubber = com.aptana.ruby.internal.core.index.CoreStubber rescue com.aptana.editor.ruby.CoreStubber

def index(filepath)
  file = org.eclipse.core.resources.ResourcesPlugin.workspace.root.getFileForLocation(org.eclipse.core.runtime.Path.new(filepath))
  return nil unless file
  project = file.project
  index_manager.getIndex(project.locationURI)
end

def index_manager
  com.aptana.index.core.IndexManager.instance
end

def ruby_core_index
  CoreStubber.getRubyCoreIndex
end

def std_lib_indices 
  loadpaths = CoreStubber.getLoadpaths
  loadpaths.collect {|l| index_manager.getIndex(l.toFile.toURI) }.compact
end

def gem_indices
  gem_paths = CoreStubber.getGemPaths
  gem_paths.collect {|g| index_manager.getIndex(g.toFile.toURI) }.compact
end

# returns an array of the project index, ruby core index, std lib indiced and all gem indices
def all_applicable_indices(filepath)
  indices = []
  project_index = index(filepath)
  indices << project_index if project_index
  indices << ruby_core_index
  indices << std_lib_indices
  indices << gem_indices
  indices.flatten
end
