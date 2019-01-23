# # encoding: utf-8

# Inspec test for recipe databases::default

# The Inspec reference, with examples and extensive documentation, can be
# found at http://inspec.io/docs/reference/resources/

if os.redhat?
  describe package('postgresql96-server') do
    it { should be_installed }
  end

  describe service('postgresql-9.6') do
    it { should be_running }
    it { should be_enabled }
  end

  describe file('/var/lib/pgsql/9.6/data/PG_VERSION') do
    it { should exist }
  end
elsif os.debian?
  describe package('postgresql-9.6') do
    it { should be_installed }
  end

  describe service('postgresql') do
    it { should be_running }
    it { should be_enabled }
  end
end

describe postgres_database('metrics') do
  it { should exist }
  its('table_count') { should eq(2) }
  its('tables') { should include('clicks', 'page_views') }
end
