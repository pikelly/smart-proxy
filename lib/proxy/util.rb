module Proxy::Util
  # searches for binaries in predefined directories and user PATH
  # accepts a binary name and an array of paths to search first
  # if path is ommited will search only in user PATH
  def which(bin, *path)
    path += ENV['PATH'].split(File::PATH_SEPARATOR)
    path.uniq.each do |dir|
      dest = File.join(dir, bin)
      return dest if FileTest.file? dest and FileTest.executable? dest
    end
    return false
  rescue StandardError => e
    logger.warn e
    return false
  end
end
