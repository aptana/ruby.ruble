# Given a filepath as a string, we resolve to a file in the workspace, grab it's project and then grab the relevant index for that project
def index(filepath)
  file = org.eclipse.core.resources.ResourcesPlugin.workspace.root.getFileForLocation(org.eclipse.core.runtime.Path.new(filepath))
  project = file.project
  index_manager.getIndex(project.locationURI)
end

def index_manager
  com.aptana.index.core.IndexManager.instance
end

def ruby_core_index
  com.aptana.editor.ruby.CoreStubber.getRubyCoreIndex
end

def std_lib_indices 
  loadpaths = com.aptana.editor.ruby.CoreStubber.getLoadpaths
  loadpaths.collect {|l| index_manager.getIndex(l.toFile.toURI) }.compact
end

def gem_indices
  gem_paths = com.aptana.editor.ruby.CoreStubber.getGemPaths
  gem_paths.collect {|g| index_manager.getIndex(g.toFile.toURI) }.compact
end

# returns an array of the project index, ruby core index, std lib indiced and all gem indices
def all_applicable_indices(filepath)
  indices = [index(filepath)]
  indices << ruby_core_index
  indices << std_lib_indices
  indices << gem_indices
  indices.flatten
end