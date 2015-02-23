#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

module API
  module Utilities
    module ResourceLinkParser
      def self.parse(resource_link)
        ::API::Root.routes.each do |route|
          route_options = route.instance_variable_get(:@options)

          # we are matching the resource link without trailing slashes, as they would still make
          # for a valid link (even though it does not match the compiled regex)
          match = route_options[:compiled].match(resource_link.chomp('/'))

          if match
            # we want to capture the identifying key regardless of its name (e.g. :id)
            id_key = match.names.reject { |name| ['version', 'format'].include?(name) }.first
            id = id_key ? match[id_key] : nil

            return {
              ns: /\/(?<ns>\w+)/.match(route_options[:namespace])[:ns],
              id: id
            }
          end
        end

        nil
      end
    end
  end
end
