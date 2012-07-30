# 
# Cookbook Name:: lb_haproxy
#
# Copyright RightScale, Inc. All rights reserved.  All access and use subject to the
# RightScale Terms of Service available at http://www.rightscale.com/terms.php and,
# if applicable, other agreements such as a RightScale Master Subscription Agreement.

rightscale_marker :begin
ha_version = %x{/usr/sbin/haproxy -v | grep "version"}
raise "http_authorization is not available in ths version of HA proxy: #{ha_version}" if ha_version.include?("1.3")

class Chef::Recipe
  include RightScale::App::Helper
end


# Example: node[:lb][:advanced_config][:backend_authorized_users] = "/serverid{admin:123, admin2:345}; /appserver{user1:678}"

if node[:lb][:advanced_config][:backend_authorized_users].length > 0
  log "!!!!!#{node[:lb][:advanced_config][:backend_authorized_users]}"
  base_string =node[:lb][:advanced_config][:backend_authorized_users] #= "/serverid{admin:123, admin2:345}; /appserver{user1:678}"
  user_arr = base_string.split "; "

  cred_store = Hash.new

  user_arr.each do |record|
    backend_name = record[/(.+)\{/][$1]  # => /serverid
    users = record[/\{(.+)\}/][$1] # -> admin:123, admin2:345
    user_array = users.split ", " # -> ["admin:123" "admin2:345"]
    cred_store["#{backend_name}"]= user_array

    backend_short_name = get_vhost_short_name(backend_name)
    log "!!! Short name is  #{backend_short_name} "
    log "!!!!!! we will put in #{cred_store["#{backend_name}"]} Here"

    lb backend_short_name do
      backend_authorized_users  cred_store["#{backend_name}"]
      action :advanced_configs
    end
  end

end


rightscale_marker :end
