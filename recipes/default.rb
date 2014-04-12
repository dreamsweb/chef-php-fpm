#
# Author::  Seth Chisamore (<schisamo@opscode.com>)
# Cookbook Name:: php-fpm
# Recipe:: default

service_provider = nil

if node['platform'] == 'ubuntu'
  # if node['platform_version'].to_f <= 10.04
  #   # Configure Brian's PPA
  #   # We'll install php5-fpm from the Brian's PPA backports
  #   apt_repository "brianmercer-php" do
  #     uri "http://ppa.launchpad.net/brianmercer/php/ubuntu"
  #     distribution node['lsb']['codename']
  #     components ["main"]
  #     keyserver "keyserver.ubuntu.com"
  #     key "8D0DC64F"
  #     action :add
  #   end
  #   # FIXME: apt-get update didn't trigger in above
  #   execute "apt-get update"
  # end

  execute "apt-get update"

  package 'php5-cli'
  package 'php5-common'
  package 'php5-mysql'
  package 'php5-suhosin'
  package 'php5-gd'
  package 'php5-cgi'
  package 'php-pear'
  package 'php5-mcrypt'

  if node['platform_version'].to_f >= 13.10
    service_provider = ::Chef::Provider::Service::Upstart
  end
end

php_fpm_service_name = "php5-fpm"

package php_fpm_service_name do
  action :upgrade
end

template node['php-fpm']['conf_file'] do
  source "php-fpm.conf.erb"
  mode 00644
  owner "root"
  group "root"
  notifies :restart, "service[php-fpm]"
end

service "php-fpm" do
  provider service_provider if service_provider
  service_name php_fpm_service_name
  supports :start => true, :stop => true, :restart => true, :reload => true
  action [ :enable, :start ]
end

if node['php-fpm']['pools']
  node['php-fpm']['pools'].each do |pool|
    php_fpm_pool pool[:name] do
      pool.each do |k, v|
        self.params[k.to_sym] = v
      end
    end
  end
end
