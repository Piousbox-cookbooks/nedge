
#
# Configure the freshly (re-)built ccow system.
#

def puts! arg, label=''
  puts "+++ +++ #{label}"
  puts arg.inspect
end

nedge_app = data_bag_item 'nexenta', 'nedge'
path = nedge_app['path']
path = '/' == path[path.length-1] ? path[0...(path.length-1)] : path # remove final slash
override_interface = node['nedge']['override_interface'] || 'eth0'
failure_domain = node['nedge']['failure_domain'] || 0

# create storage nodes
for i in 1..nedge_app['n_devices']
  directory "/data/store#{i}" do
    action :create
    recursive true
  end
end

template "#{path}/etc/ccow/rt-lfs.json" do
  source "etc/ccow/rt-lfs.json.erb"
  variables({
              :n_devices => nedge_app['n_devices']
            })
end
template "#{path}/etc/ccow/ccow.json" do
  source "etc/ccow/ccow.json.erb"
  variables({
              :failure_domain => failure_domain,
              :override_interface => override_interface
            })
end
template "#{path}/etc/ccow/ccowd.json" do
  source "etc/ccow/ccowd.json.erb"
  variables({
              :override_interface => override_interface
            })
end
template "#{path}/etc/corosync/corosync.conf" do
  source "etc/corosync/corosync.conf.erb"
  variables({
              :override_interface => override_interface
            })
end

# set the mtu && enable ipv6
execute "ifconfig #{override_interface} mtu 9000" do
  user 'root'
end
execute "sysctl net.ipv6.conf.all.disable_ipv6=0" do
  user 'root'
end

# restart corosync
execute "restart corosync" do
  command "#{path}/etc/init.d/corosync restart"
  user 'root'
end


