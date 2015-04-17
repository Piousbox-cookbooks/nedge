
#
# Nedge DEVELOPMENT base.
# So far, packages only.
#

def puts! arg, label=''
  puts "+++ +++ #{label}"
  puts arg.inspect
end

nedge_app = data_bag_item 'nexenta', 'nedge'

nedge_app['apt_packages'].each do |package_name|
  package package_name do
    action :install
  end
end

