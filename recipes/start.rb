
#
# Start NEF services (for object).
#

def puts! arg, label=''
  puts "+++ +++ #{label}"
  puts arg.inspect
end

nedge_app = data_bag_item 'nexenta', 'nedge'
path = nedge_app['path']
path = '/' == path[path.length-1] ? path[0...(path.length-1)] : path # remove final slash

if File.exist?( "#{path}/.do_not_restart" )
  execute "Not (re-)starting services because file #{path}/.do_not_restart is present."
else
  execute "Do nefstart" do
    command "screen -S nedge_screen -d -m && sleep 3 &&
             screen -r nedge_screen -X stuff $'. #{path}/env.sh && #{path}/scripts/dev/gw-kill.sh ; #{path}/scripts/dev/gw-kill.sh ; sleep 4 ;
                                               rm -rf /data/*/* ; rm -rf /data/*/.* ;
                                               #{path}/etc/init.d/corosync restart && 
                                               CCOW_LOG_LEVEL=4 CCOW_LOG_COLORS=1 #{path}/src/nmf/nefstart -a & 
                                               echo \"Sleeping 10sec...\" ; sleep 10 ;
                                               \n'
            "
    user 'root'
  end
  # Enable all workers
  node['nedge']['workers'].each do |worker_name|
    execute "sleep 3 && . #{path}/env.sh && #{path}/src/nmf/nefadm enable #{worker_name} && sleep 3" do
      user 'root'
    end
  end
  execute "Do cluster_test" do
    command ". #{path}/env.sh && #{path}/src/ccow/test/cluster_test -n"
    user 'root'
  end
end

