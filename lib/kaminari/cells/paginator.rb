module Kaminari
  module Cells

    class Paginator < Tag

      # in kaminari views you can call render() with a block on a paginator object
      # but render is used in cells, too.
      # So we try to differentiate by checking if block is given.
      def render(*args)
        if block_given?
          yield if options[:total_pages] > 1
        else
          super
        end
      end

      private

      def window_options
        @window_options ||= {}.tap do |h|
          h[:window] = options.delete(:window) || options.delete(:inner_window) || Kaminari.config.window
          outer_window = options.delete(:outer_window) || Kaminari.config.outer_window
          h[:left] = options.delete(:left) || Kaminari.config.left
          h[:left] = outer_window if h[:left] == 0
          h[:right] = options.delete(:right) || Kaminari.config.right
          h[:right] = outer_window if h[:right] == 0
          h.merge!(options)
          h[:current_page] = PageProxy.new(h, options[:current_page], nil)
        end
      end

      def current_page
        @current_page ||= window_options[:current_page]
      end

      def paginator
        self
      end

      # enumerate each page providing PageProxy object as the block parameter
      # Because of performance reason, this doesn't actually enumerate all pages but pages that are seemingly relevant to the paginator.
      # "Relevant" pages are:
      # * pages inside the left outer window plus one for showing the gap tag
      # * pages inside the inner window plus one on the left plus one on the right for showing the gap tags
      # * pages inside the right outer window plus one for showing the gap tag
      def each_relevant_page
        return to_enum(:each_relevant_page) unless block_given?

        relevant_pages(window_options).each do |page|
          yield PageProxy.new(window_options, page, @last)
        end
      end
      alias each_page each_relevant_page

      def relevant_pages(options)
        left_window_plus_one = 1.upto(options[:left] + 1).to_a
        right_window_plus_one = (options[:total_pages] - options[:right]).upto(options[:total_pages]).to_a
        inside_window_plus_each_sides = (options[:current_page] - options[:window] - 1).upto(options[:current_page] + options[:window] + 1).to_a

        (left_window_plus_one + inside_window_plus_each_sides + right_window_plus_one).uniq.sort.reject {|x| (x < 1) || (x > options[:total_pages])}
      end
      private :relevant_pages

      def page_tag(page)
        @last = Page.new @template, @options.merge(:page => page)
      end

      %w[first_page prev_page next_page last_page gap].each do |tag|
        eval <<-DEF
          def #{tag}_tag
            @last = concept("kaminari/cells/#{tag}", model, options.merge(current_page: current_page))
          end
        DEF
      end

      # Wraps a "page number" and provides some utility methods
      class PageProxy
        include Comparable

        def initialize(options, page, last) #:nodoc:
          @options, @page, @last = options, page, last
        end

        # the page number
        def number
          @page
        end

        # current page or not
        def current?
          @page == @options[:current_page]
        end

        # the first page or not
        def first?
          @page == 1
        end

        # the last page or not
        def last?
          @page == @options[:total_pages]
        end

        # the previous page or not
        def prev?
          @page == @options[:current_page] - 1
        end

        # the next page or not
        def next?
          @page == @options[:current_page] + 1
        end

        # relationship with the current page
        def rel
          if next?
            'next'
          elsif prev?
            'prev'
          end
        end

        # within the left outer window or not
        def left_outer?
          @page <= @options[:left]
        end

        # within the right outer window or not
        def right_outer?
          @options[:total_pages] - @page < @options[:right]
        end

        # inside the inner window or not
        def inside_window?
          (@options[:current_page] - @page).abs <= @options[:window]
        end

        def single_gap?
          (@page == @options[:current_page] - @options[:window] - 1) && (@page == @options[:left] + 1) ||
            (@page == @options[:current_page] + @options[:window] + 1) && (@page == @options[:total_pages] - @options[:right])
        end

        def out_of_range?
          @page > @options[:total_pages]
        end

        # The last rendered tag was "truncated" or not
        def was_truncated?
          @last.is_a? Gap
        end

        def to_i
          number
        end

        def to_s
          number.to_s
        end

        def +(other)
          to_i + other.to_i
        end

        def -(other)
          to_i - other.to_i
        end

        def <=>(other)
          to_i <=> other.to_i
        end
      end

    end

  end
end
