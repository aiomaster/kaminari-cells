require "cells"
require "kaminari"
require "kaminari/cells/version"
require "kaminari/cells/tags"
require "kaminari/cells/paginator"

module Kaminari
  module Helpers
    module CellsHelper
      def paginate(scope, options = {})
        concept('kaminari/cells/paginator', scope, options.reverse_merge(:current_page => scope.current_page, :total_pages => scope.total_pages, :per_page => scope.limit_value, :remote => false)).()
      end
    end
  end
end

require 'kaminari/cells'
