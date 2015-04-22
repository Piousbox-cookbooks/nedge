
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

# install all gems
node['ruby_gems'] && node['ruby_gems'].each do |gem_name|
  gem_package gem_name do
    action :install
  end
end
