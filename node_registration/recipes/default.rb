#
# Cookbook Name:: node_registration
# Recipe:: default
#
# Copyright (c) 2017 The Authors, All Rights Reserved.

#install aws cli
package "awscli"

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
  curl -L https://www.opscode.com/chef/install.sh | bash -s -- -v 11.16.0
  aws s3 cp --region "eu-west-1" s3://thilinam-base-privatekeybucket-wt1l6xcd2e1u/chef-validator.pem  .
  aws s3 cp --region "eu-west-1" s3://thilinam-base-privatekeybucket-wt1l6xcd2e1u/data_bag_secret  .
  cp -f /tmp/chef-validator.pem /etc/chef/validation.pem 
  cp -f /tmp/data_bag_secret /etc/chef/data_bag_secret
  # Bootstrap Chef Client
  mkdir -p /var/chef/cache /var/chef/cookbooks/chef-client /var/chef/cookbooks/cron /var/chef/cookbooks/logrotate
  wget -qO- https://github.com/opscode-cookbooks/cron/archive/v1.2.6.tar.gz | tar xvzC /var/chef/cookbooks/cron --strip-components=1
  wget -qO- https://github.com/opscode-cookbooks/logrotate/archive/v1.3.0.tar.gz | tar xvzC /var/chef/cookbooks/logrotate --strip-components=1
  wget -qO- https://github.com/opscode-cookbooks/chef-client/archive/v3.7.0.tar.gz | tar xvzC /var/chef/cookbooks/chef-client --strip-components=1
  sudo chef-solo -j /etc/chef/chef.json > /tmp/chef_solo.log 2>&1 
  # Execute roles
  sudo chef-client -j /etc/chef/roles.json --once > /tmp/chef_client.log 2>&1 
  EOH
end
