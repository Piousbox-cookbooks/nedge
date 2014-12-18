
def puts! arg, label
  puts "+++ +++ #{label}"
  puts arg.inspect
end

nedge_app = data_bag_item( 'nexenta', 'nedge' )
path = nedge_app['path']
path = '/' == path[path.length-1] ? path[0...(path.length-1)] : path # remove final slash
user = nedge_app['user']
# user_dir = 'root' == user ? '/root' : "/home/#{user}"
user_dir = Dir.home( user )

# put 'sudo' there in the string to run commands as sudo.
sudo = nedge_app['use_sudo'] ? 'sudo ' : ''

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
  command "#{sudo} git clone ssh://git@stash.nexenta.com:7999/ned/nedge.git"
  not_if "test -d #{path}"
end

# make clean && make install

# 
