require "yaml"
require "ostruct"

if defined? Testing
  # If there is a settings file in lib/test when running tests then use this. Test_helper.rb defines Testing
  file = Pathname.new("test/settings.yml")
elsif ORIGIN =~ "^/usr"
  # If we are runing from /usr/the use /etc/smart-proxy/settings.yml
  file = Pathname.new("/etc/smart-proxy/settings.yml")
else
  # Otherwise use the one in the build tree
  file = Pathname.new(__FILE__).join("..", "..","..","config","settings.yml")
end
raw_config = File.read(file)

class Settings < OpenStruct
  def method_missing args
    false
  end
end

settings = YAML.load(raw_config)
if PLATFORM =~ /mingw/
  settings.delete :puppetca if settings.has_key? :puppetca
  settings.delete :puppet   if settings.has_key? :puppet
end
SETTINGS = Settings.new(settings)
