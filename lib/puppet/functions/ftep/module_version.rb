Puppet::Functions.create_function(:'ftep::module_version') do
  dispatch :find_module_version do
    required_param 'String[1]', :module_name
    return_type 'String'
  end

  def find_module_version(module_name)
    if File.exist?(Pathname.new(__FILE__).dirname.join("../../../../../%s/metadata.json" % module_name))
      return get_module_version(Pathname.new(__FILE__).dirname.join("../../../../../%s/metadata.json" % module_name))
    elsif File.exist?(Pathname.new(__FILE__).dirname.join("../../../../../../modules/%s/metadata.json" % module_name))
      return get_module_version(Pathname.new(__FILE__).dirname.join("../../../../../../modules/%s/metadata.json" % module_name))
    elsif File.exist?(Pathname.new(__FILE__).dirname.join("../../../../../../local-modules/%s/metadata.json" % module_name))
      return get_module_version(Pathname.new(__FILE__).dirname.join("../../../../../../local-modules/%s/metadata.json" % module_name))
    else
      raise "Failed to locate module %s to resolve version" % module_name
    end
  end

  def get_module_version(metadata_path)
    JSON.parse(File.read(metadata_path))['version']
  end
end
