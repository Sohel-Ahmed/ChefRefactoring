# Setup PostgreSQL Install
extend Databases::Helpers

postgresql_version = '9.6'

if is_rhel?  
  remote_file "/etc/pki/rpm-gpg/RPM-GPG-KEY-PGDG-#{postgresql_version}" do
    source "https://download.postgresql.org/pub/repos/yum/RPM-GPG-KEY-PGDG"
  end

  yum_repository "PostgreSQL #{postgresql_version}" do # ~FC005
    repositoryid "pgdg#{postgresql_version}"
    description "PostgreSQL.org #{postgresql_version}"
    if is_fedora?
      baseurl 'https://download.postgresql.org/pub/repos/yum/9.6/fedora/fedora-$releasever-$basearch'
    else
      baseurl 'https://download.postgresql.org/pub/repos/yum/9.6/redhat/rhel-$releasever-$basearch'
    end
    enabled     true
    gpgcheck    true
    gpgkey      "file:///etc/pki/rpm-gpg/RPM-GPG-KEY-PGDG-#{postgresql_version}"
  end
  package "postgresql#{postgresql_version.delete('.')}-server"
  elsif is_debian?
   apt_update

   package 'language-pack-en'
   package 'apt-transport-https'

  apt_repository 'postgresql_org_repository' do
    uri          'https://download.postgresql.org/pub/repos/apt/'
    components   ['main', postgresql_version]
    distribution "#{node['lsb']['codename']}-pgdg"
    key "https://download.postgresql.org/pub/repos/apt/ACCC4CF8.asc"
    cache_rebuild true
  end
  package "postgresql-#{postgresql_version}"
  cookbook_file "/etc/postgresql/#{postgresql_version}/main/pg_hba.conf" do
    source "pg_hba.conf"
  end
else
  raise "The platform_family '#{node['platform_family']}' or platform '#{node['platform']}' is not supported by this cookbook."
end

# Initialize Database
execute 'init_db' do
  command "/usr/pgsql-#{postgresql_version}/bin/initdb -D /var/lib/pgsql/#{postgresql_version}/data"
  user 'postgres'
  not_if { ::File.exists?("/var/lib/pgsql/#{postgresql_version}/data/PG_VERSION") }
  only_if { is_rhel? }
end

# Start Database Service
service 'postgresql' do
  if is_rhel?
    service_name "postgresql-#{postgresql_version}"
  elsif is_debian?
    service_name 'postgresql'
  end
  action [:start, :enable]
end

# Set postgres User Password
if node['postgres_password']
  bash 'set-postgres-password' do
    user 'postgres'
    code "/usr/bin/psql -c \"ALTER ROLE postgres ENCRYPTED PASSWORD '#{node['postgres_password']}';\" -U postgres"
    not_if do
      # Don't set password if it is already set
      sql = %(SELECT rolpassword from pg_authid WHERE rolname='postgres' AND rolpassword IS NOT NULL;)
      query = shell_out("/usr/bin/psql -c \"#{sql}\" -U postgres", user: 'postgres')
      query.stdout =~ /1 row/ ? true : false
    end
  end
end

# Create Databases based on content from DB API

Databases::API.new(node['db_role']).fetch_databases do |databases|
  databases.each do |db|
    db_sql = db['tables'].join()

    db_exists = lambda do
      sql = %(SELECT datname from pg_database WHERE datname='#{db['name']}')
      query = shell_out("/usr/bin/psql -c \"#{sql}\" -U postgres", user: 'postgres')
      query.stdout =~ /1 row/ ? true : false
    end.call()

    bash "create-db-#{db['name']}" do
      user 'postgres'
      code "createdb -E UTF-8 -U postgres #{db["name"]}"
      not_if { db_exists }
    end

    bash "create-tables-for-#{db['name']}" do
      user 'postgres'
      code "/usr/bin/psql -c \"#{db_sql}\" -U postgres -d #{db['name']}"
      not_if { db_exists }
    end
  end
end
