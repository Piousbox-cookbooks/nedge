
#
# Workplace config recipe.
# sets up some nifty options and shortcuts for when you are working on nedge.
#

nedge_app = data_bag_item('nexenta', 'nedge')

user = nedge_app['user']
user_dir = 'root' == user ? "/root" : "/home/#{user}"

# ~/.screenrc
cookbook_file "#{user_dir}/.screenrc" do
  action :create_if_missing
  source "root/screenrc"
end

# ~/.bashrc
bashrc_original_content = File.read( "#{user_dir}/.bashrc" )
if bashrc_original_content.include?( "source #{user_dir}/.bashrc-nedge" )
  # do nothing
else
  template "#{user_dir}/.bashrc-nedge" do
    source "root/bashrc-nedge.erb"
    variables({})
  end
  execute "adding .bashrc-nedge to .bashrc" do
    command ' echo "source #{user_dir}/.bashrc-nedge" >> #{user_dir}/.bashrc '
end


