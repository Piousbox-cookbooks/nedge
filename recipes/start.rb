
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
  execute "echo \"Not (re-)starting services because file #{path}/.do_not_restart is present.\" " do
    user 'root'
  end
else
  execute "kill screens if any" do
    command " screen -ls | grep nedge_screen | cut -d. -f1 | awk '{print $1}' | xargs kill "
    user 'root'
    # only if such screen exists
    not_if "if test x`screen -ls | grep nedge_screen | cut -d. -f1 | awk '{print $1}' | wc -w` = x0; then true; fi"
  end
  execute "Do nef cleanup" do
    command <<-HEREDOC
             screen -S nedge_screen -d -m && sleep 3 &&
             screen -r nedge_screen -X stuff " source #{path}/env.sh &&
                                               #{path}/scripts/dev/gw-kill.sh ; sleep 2 ;
                                               #{path}/scripts/dev/gw-kill.sh ; sleep 2 ;
                                               rm -rf /data/*/* ; rm -rf /data/*/.* ;
                                               #{path}/etc/init.d/corosync restart && echo ok
                                               \n "
            HEREDOC
    user 'root'
  end
  execute "Do cluster_test" do
    command <<-HEREDOC
             screen -r nedge_screen -X stuff " source #{path}/env.sh && 
                                               #{path}/src/ccow/test/cluster_test
                                               \n "
            HEREDOC
    user 'root'
  end
  execute "Do nefstart" do
    command <<-HEREDOC
             screen -r nedge_screen -X stuff " source #{path}/env.sh &&
                                               CCOW_LOG_LEVEL=4 CCOW_LOG_COLORS=1 #{path}/src/nmf/nefstart -a & 
                                               \n "
            HEREDOC
    user 'root'
  end
  # Enable all workers
  # This does not work for some reason...
  node['nedge']['workers'].each do |worker_name|
    bash "enable worker #{worker_name}" do
      cwd path
      code <<-HEREDOC
               source #{path}/env.sh && echo "blahblah" # #{path}/src/nmf/nefadm enable #{worker_name}
            HEREDOC
      user 'root'
    end
  end
  execute "touch #{path}/.do_not_restart" do
    user 'root'
  end
end

