
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

# create storage nodes
for i in 1..nedge_app['n_devices']
  directory "/data/store#{i}" do
    action :create
  end
end

# alter rt-lfs.json
template "#{path}/etc/ccow/rt-lfs.json" do
  source "etc/ccow/rt-lfs.json.erb"
  variables({
              :n_devices => nedge_app['n_devices']
            })
end

# set failure_domain policy

# configure corosync
# set rrp_mode
# configure the interface {} block
# remove the duplicate interface {} block (if any)

# set the mtu && enable ipv6

# restart corosync





