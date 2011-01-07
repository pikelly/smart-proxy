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
  t.libs << 'test'
  t.pattern = 'test/**/*_test.rb'
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
  s.name = "foreman_proxy"
  s.version = "0.0.2"
  s.author = "Ohad Levy"
  s.email = "ohadlevy@gmail.com"
  s.homepage = "http://theforeman.org/"
  s.platform = Gem::Platform::RUBY
  s.summary = "Foreman Proxy Agent, manage remote DHCP, DNS, TFTP and Puppet servers"
  s.files = FileList["{bin,public,config,views,lib}/**/*"].to_a
  s.default_executable = 'bin/smart_proxy.rb'
  s.require_path = "lib"
  s.test_files = FileList["{test}/**/*test.rb"].to_a
  s.has_rdoc = true
  s.extra_rdoc_files = ["README"]
  s.add_dependency 'json'
  s.add_dependency 'sinatra'
  s.rubyforge_project = 'rake'
  s.description = <<EOF
Foreman Proxy is used via The Foreman Project, it allows Foreman to manage
Remote DHCP, DNS, TFTP and Puppet servers via a REST API
EOF
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
