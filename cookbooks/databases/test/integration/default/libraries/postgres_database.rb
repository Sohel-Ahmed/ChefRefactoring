class PostgresDatabase < Inspec.resource(1)
  name 'postgres_database'

  desc 'Check PostgreSQL Database Configuration'

  example "
    describe postgres_database('example') do
      it { should exist }
      its('tables') { should eq(['a', 'b'] }
    end
  "

  attr_accessor :db_name, :user

  def initialize(db_name, user: 'postgres')
    self.db_name = db_name
    self.user = user
  end

  def exists?
    sql = %(SELECT datname from pg_database WHERE datname='#{db_name}')
    cmd = execute_sql(sql)
    cmd.exit_status == 0
  end

  def tables
    return @tables if defined?(@tables)
    sql = "\\dt"
    cmd = execute_sql(sql)

    if cmd.exit_status == 0 && !cmd.stdout.include?('0 rows')
      # Skip initial output, header lines, and row count
      table_lines = cmd.stdout.strip.split("\n")[3...-1]
      @tables = table_lines.flat_map do |line|
        line.split("|")[1].strip
      end
    else
      @tables = []
    end
  end

  def table_count
    tables.count
  end

  def to_s
    "PostgreSQL Database #{db_name}"
  end

  private

  def execute_sql(sql)
    cmd = "/usr/bin/psql -c \"#{sql}\" -d #{db_name} -U #{self.user}"
    inspec.bash(cmd, user: user)
  end
end
