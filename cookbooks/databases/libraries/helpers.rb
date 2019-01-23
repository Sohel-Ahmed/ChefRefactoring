module Databases
  module Helpers
    RHEL_FAMILIES = ['rhel', 'fedora']

    def is_rhel?
      RHEL_FAMILIES.include?(node['platform_family'])
    end
    def is_fedora?
      node['platform_family'] == 'fedora'
    end
    def is_debian?
      node['platform_family'] == 'debian'
    end
  end
end

Chef::Resource.class_eval { include Databases::Helpers }


