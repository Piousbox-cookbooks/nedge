
#
# Configure the freshly (re-)built ccow system.
#

def puts! arg, label=''
  puts "+++ +++ #{label}"
  puts arg.inspect
end

#
# From: https://gist.github.com/mrunalp/9629571
# Get IP address for an interface in ruby.
#
require 'socket'
require 'ipaddr'
# From ioctls.h
SIOCGIFADDR    = 0x8915
def ip_address(iface)
    sock = UDPSocket.new
    buf = [iface,""].pack('a16h16')
    sock.ioctl(SIOCGIFADDR, buf);
    sock.close
    buf[20..24].unpack("CCCC").join(".")
end 
#puts ip_address('em1')
#puts ip_address(override_interface)



nedge_app = data_bag_item 'nexenta', 'nedge'
path = nedge_app['path']
path = '/' == path[path.length-1] ? path[0...(path.length-1)] : path # remove final slash
override_interface = node['nedge']['override_interface'] || 'eth0'
failure_domain = node['nedge']['ccow.json']['failure_domain'] || 0

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
  owner 'root'
end

template "#{path}/etc/ccow/ccow.json" do
  source "etc/ccow/ccow.json.erb"
  variables({
              :failure_domain => failure_domain,
              :tenant_cmcache_size => node['nedge']['ccow.json']['tenant_cmcache_size'],
              :tenant_cmcache_buckets => node['nedge']['ccow.json']['tenant_cmcache_buckets'],
              :tenant_ucache_size => node['nedge']['ccow.json']['tenant_ucache_size'],
              :override_interface => override_interface,
              :verify_chid => node['nedge']['ccow.json']['verify_chid'],
              :join_delay => node['nedge']['ccow.json']['join_delay']
            })
  owner 'root'
end

template "#{path}/etc/ccow/ccowd.json" do
  source "etc/ccow/ccowd.json.erb"
  variables({
              :override_interface => override_interface
            })
  owner 'root'
end

template "#{path}/etc/ccow/auditd.ini" do
  source "etc/ccow/auditd.ini.erb"
  variables({})
  owner 'root'
end

nodeid = ip_address(override_interface).split(".")[3] # the last hex of that IP
template "#{path}/etc/corosync/corosync.conf" do
  source "etc/corosync/corosync.conf.erb"
  variables({
              :override_interface => override_interface,
              :nodeid => nodeid
            })
  owner 'root'
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

# generate ver/run/
directory "#{path}/var/run" do
  action :create
  recursive true
end
execute "touch #{path}/var/run/serverid.cache"
