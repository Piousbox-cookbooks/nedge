
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
if bashrc_original_content.include?( "nedge shortcuts" )
  # do nothing
else
  template "#{user_dir}/.bashrc" do
    source "root/bashrc.erb"
    variables({
                :original_content => bashrc_original_content
              })
  end
end


