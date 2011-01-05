require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require 'rake/packagetask'
require 'rake/gempackagetask'

desc 'Default: run unit tests.'
task :default => :test

desc 'Test the Foreman Proxy plugin.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.libs << 'lib/proxy'
  t.libs << 'test'
  files = FileList['test/**/*_test.rb']
  files.delete_if{|f| f =~ /_ms_/} unless PLATFORM =~ /mingw/
  t.test_files  = files
  t.verbose = true
end

desc 'Generate documentation for the Foreman Proxy plugin.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'Proxy'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

spec = Gem::Specification.new do |s|
  s.name = "smart-proxy"
  s.version = "0.0.1"
  s.author = "Ohad Levy"
  s.email = "ohadlevy@gmail.com"
  s.homepage = "http://theforeman.org/"
  s.platform = Gem::Platform::CURRENT
  s.summary = "Foreman Proxy Agent, manage remote DHCP, DNS, TFTP and Puppet servers"
  s.files = FileList["{bin,public,config,views,lib,log,tasks,test}/**/*","extra/*","Rakefile","README", "copyright" ].exclude(/\/Kdy|dgem|drake|\.log$|\.pem$|\.pid|\.output/)
  s.default_executable = 'smart-proxy'
  s.executables = ['smart-proxy', 'configure-smart-proxy.rb']
  s.require_path = "lib"
  s.test_files = FileList.new("{test}/**/*test.rb").to_a
  s.has_rdoc = true
  s.extra_rdoc_files = ["README"]
  s.add_dependency(%q<haml>, [">= 3.0.24"])
  s.add_dependency(%q<json>, [">= 1.4.6"])
  s.add_dependency(%q<highline>, [">= 1.6.1"])
  s.add_dependency(%q<rest-client>, [">= 1.6.1"])
  s.add_dependency(%q<sinatra>, ["= 1.1.0"])
  s.add_dependency(%q<net-ping>, [">= 1.3.7"])

  s.add_development_dependency(%q<ruby-debug-base>, [">= 0.10.4"])
  s.add_development_dependency(%q<ruby-debug-ide>, [">= 0.4.11"])
  s.description = <<EOF
Foreman Proxy is used by The Foreman Project.
 it allows Foreman to manage
 Remote DHCP, DNS, TFTP and Puppet servers via a RESTful API
EOF
end

if Gem.win_platform?
  spec.add_dependency(%q<rack>,          ["= 1.2.0"])
  spec.add_dependency(%q<win32-api>,     [">= 1.4.6"])
  spec.add_dependency(%q<win32-open3>,   [">= 0.3.2"])
  spec.add_dependency(%q<win32-service>, [">= 0.3.2"])
else
  spec.add_dependency(%q<rack>, ["= 1.2.1"])
end

Rake::GemPackageTask.new(spec) do |pkg|
    pkg.need_tar_gz = true
end
require "lib/tasks/dpkgtask"
require 'ostruct'
control = OpenStruct.new(
  "Package"        => "smart-proxy",
  "Version"        => "1.0.0-1",
  "Section"        => "web" ,
  "Priority"       => "optional",
  "Architecture"   => "all",
  "Depends"        => "ruby (>= 1.8)",
  "Pre-Depends"    => "perl",
  "Recommends"     => "mozilla | netscape",
  "Suggests"       => "foreman, puppetmaster, bind9, dhcp3-server, atftpd",
  "Installed-Size" => "10240",
  "Maintainer"     => "Paul Kelly <paul.ian.kelly@goglemail.com>",
  "Description"    => "Smart Proxy is used by The Foreman Project
 it allows Foreman to manage
 remote DHCP, DNS, TFTP and Puppet servers via a RESTful API"
)
Rake::DpkgTask.new(control) do |t|
  t.lib_files     = FileList["{public,views,lib,tasks,test}/**/*", "extra/*", "Rakefile", "README"]
  t.sbin_files    = FileList["bin/**/*"].exclude(/drake/)
  t.config_files  = FileList["config/*"].exclude(/\/Kdy|\.pem$/)
  t.doc_files     = FileList["copyright"]
  t.control_files = FileList["extra/build/{preinst,postinst,prerm,postrm}"]
end
