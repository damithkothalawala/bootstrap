#
# Cookbook Name:: node_registration
# Recipe:: default
#
# Copyright (c) 2017 The Authors, All Rights Reserved.

#install aws cli
package "awscli"

bash "install_chef" do
	code <<-EOH
	curl -L https://www.opscode.com/chef/install.sh | bash -s -- -v 11.16.0
	EOH
end
template "/etc/chef/chef.json" do
	source "chef.json.erb"
end

template "/etc/chef/roles.json" do
	source "roles.json.erb"
end

bash "s3_downloads" do
  user 'root'
  cwd '/tmp'
  code <<-EOH
  # Bootstrap chef
  rm -f /etc/chef/client.pem /etc/chef/client.rb | true
  aws s3 cp --region "eu-west-1" s3://thilinam-base-privatekeybucket-wt1l6xcd2e1u/chef-validator.pem  . | true
  aws s3 cp --region "eu-west-1" s3://thilinam-base-privatekeybucket-wt1l6xcd2e1u/data_bag_secret  . | true
  cp -f /tmp/chef-validator.pem /etc/chef/validation.pem | true
  cp -f /tmp/data_bag_secret /etc/chef/encrypted_data_bag_secret | true
  # Bootstrap Chef Client
  mkdir -p /var/chef/cache /var/chef/cookbooks/chef-client /var/chef/cookbooks/cron /var/chef/cookbooks/logrotate | true
  wget -qO- https://github.com/opscode-cookbooks/cron/archive/v1.2.6.tar.gz | tar xvzC /var/chef/cookbooks/cron --strip-components=1 | true
  wget -qO- https://github.com/opscode-cookbooks/logrotate/archive/v1.3.0.tar.gz | tar xvzC /var/chef/cookbooks/logrotate --strip-components=1 | true
  wget -qO- https://github.com/opscode-cookbooks/chef-client/archive/v3.7.0.tar.gz | tar xvzC /var/chef/cookbooks/chef-client --strip-components=1 | true
  #/usr/bin/chef-solo -j /etc/chef/chef.json > /tmp/chef_solo.log  
  # Execute roles
  #/usr/bin/chef-client  -j /etc/chef/roles.json --once > /tmp/chef_client.log 2>&1 
  EOH
end

execute 'initiate_registration' do
  command '/usr/bin/chef-solo -j /etc/chef/chef.json'
end

execute 'initiate_chef_client' do
  command '/usr/bin/chef-client  -j /etc/chef/roles.json --once'
end
