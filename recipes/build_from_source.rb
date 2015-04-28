
def puts! arg, label=''
  puts "+++ +++ #{label}"
  puts arg.inspect
end

nedge_app = data_bag_item( 'nexenta', 'nedge' )
path = nedge_app['path']
path = '/' == path[path.length-1] ? path[0...(path.length-1)] : path # remove final slash
user = nedge_app['user']
user_dir = Dir.home( user )
sudo = nedge_app['use_sudo'] ? 'sudo ' : '' # put 'sudo' there in the string to run commands as sudo.

## prevent massive timeout
## does this make in hang?
# execute "echo \"no_lazy_load true\" >> /etc/chef/client.rb" do
#   not_if "cat /etc/chef/client.rb | grep no_lazy_load"
# end

# check out the repo
cookbook_file "#{user_dir}/.ssh/config" do
  action :create_if_missing
  source "root/ssh/config"
end
cookbook_file "#{user_dir}/.ssh/id_rsa_stash_nexenta_com" do
  action :create_if_missing
  source "root/ssh/id_rsa_stash_nexenta_com"
  mode "0600"
end
execute "git clone" do
  cwd path[0...path.rindex('/')]
  command "#{sudo} git clone #{nedge_app['repository']}"
  not_if "test -d #{path}"
end

execute "git pull" do
  cwd path
  command "#{sudo} git pull origin #{nedge_app['branch']}"
end

# make clean install
if File.exist?("#{path}/.deploy-dev")
  make_clean = 'make clean'
else
  make_clean = 'echo \"skipping make clean because file .deploy-dev is absent.\"'
end
if node['nedge']['force_recompile'] || !File.exist?( "#{path}/install" )
  if nedge_app['enable_address_sanitizer']
    execute "make install" do
      cwd path
      command ". #{path}/env.sh && #{make_clean} && make install"
    end
  else
    execute "make install" do
      cwd path
      command ". #{path}/env.sh && #{make_clean} && make NEDGE_NDEBUG=1 install"
    end
    ## the `make install` step already does this.
    # execute "compile ccow" do
    #   cwd "#{path}/src/ccow"
    #   command ". #{path}/env.sh && ./configure --prefix=#{path} --disable-address-sanitizer && make -j88"
    # end
  end
  execute "#{path}/scripts/dev/nedge-dev-cleanup.sh"
  execute "npm install" do
    cwd "#{path}/src/nmf"
    command ". #{path}/env.sh && npm install"
  end
end

execute "echo 0 > /proc/sys/fs/suid_dumpable" do
  command "echo 0 > /proc/sys/fs/suid_dumpable"
end
