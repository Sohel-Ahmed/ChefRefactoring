if node['platform_family'] == 'rhel'
  package 'epel-release'
end

package 'nginx'

service 'nginx' do
  action [:enable, :start]
end

package 'python'

remote_file '/tmp/get-pip.py' do
  source 'https://bootstrap.pypa.io/get-pip.py'
  action :create
end

execute 'install pip' do
  command 'python /tmp/get-pip.py'
  not_if 'which pip'
end

# Create service directory
directory '/srv/db_api' do
  recursive true
end

{
  'db_api.service' => '/etc/systemd/system/',
  'db_api.py' => '/srv/db_api/',
  'wsgi.py' => '/srv/db_api/',
  'data.example.com.conf' => '/etc/nginx/conf.d/',
  'requirements.txt' => '/srv/db_api/'
}.each do |cb_file, path|
  cookbook_file "#{path}/#{cb_file}" do
    source cb_file
    notifies :reload, 'service[db_api]'
  end
end

# Install application dependencies
execute 'install-app-dependencies' do
  command 'pip install -r /srv/db_api/requirements.txt'
  not_if 'pip freeze | grep gunicorn'
end

service 'db_api' do
  action [:start, :enable]
  notifies :reload, 'service[nginx]', :immediately
end

execute 'add-db-api-to-hosts' do
  command %(echo '127.0.0.1 data.example.com' >> /etc/hosts)
  not_if 'grep data.example.com /etc/hosts'
end
