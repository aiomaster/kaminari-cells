module Kaminari
  module Cells
    PARAM_KEY_BLACKLIST = :authenticity_token, :commit, :utf8, :_method, :script_name

    # A tag stands for an HTML tag inside the paginator.
    # Basically, a tag has its own partial template file, so every tag can be
    # rendered into String using its cell template.
    #
    # The template file should be placed in your app/views/kaminari/ directory
    # with underscored class name (besides the "Tag" class. Tag is an abstract
    # class, so _tag partial is not needed).
    #   e.g.)  PrevLink  ->  app/views/kaminari/_prev_link.html.erb
    #
    # When no matching template were found in your app, the engine's pre
    # installed template will be used.
    #   e.g.)  Paginator  ->  $GEM_HOME/kaminari-x.x.x/app/views/kaminari/_paginator.html.erb
    class Tag < Trailblazer::Cell # Cell::ViewModel #

      def show
        render partial_path
      rescue Cell::TemplateMissingError
        # try with html extension and underscore_prefixed for convenience
        render partial_path(with_format: :html, underscore_prefixed: true)
      end

      private

      def page_url_for(page)
        url_for params_for(page).merge(:only_path => true)
      end

      def params_for(page)
        @cleaned_params ||= (
          # @params in Rails 5 no longer inherits from Hash
          par = params.to_unsafe_h if params.respond_to?(:to_unsafe_h)
          par.with_indifferent_access.except(*PARAM_KEY_BLACKLIST).merge(options.delete(:params) || {})
        )
        @param_name ||= (options[:param_name] || Kaminari.config.param_name)
        page_params = Rack::Utils.parse_nested_query("#{@param_name}=#{page}")
        page_params = @cleaned_params.deep_merge(page_params)

        if !Kaminari.config.params_on_first_page && (page <= 1)
          # This converts a hash:
          #   from: {other: "params", page: 1}
          #     to: {other: "params", page: nil}
          #   (when @param_name == "page")
          #
          #   from: {other: "params", user: {name: "yuki", page: 1}}
          #     to: {other: "params", user: {name: "yuki", page: nil}}
          #   (when @param_name == "user[page]")
          @param_name.to_s.scan(/[\w\.]+/)[0..-2].inject(page_params){|h, k| h[k] }[$&] = nil
        end

        page_params
      end

      def partial_path(with_format: nil, underscore_prefixed: false)
        partial_name =
          [
           options[:views_prefix],
           #'kaminari',
           options[:theme],
           "#{'_' if underscore_prefixed}#{self.class.name.demodulize.underscore}"
          ].compact.join("/")
        with_format ? "#{partial_name}.#{with_format}" : partial_name
      end

      def current_page
        options[:current_page]
      end
    end

    # Tag that contains a link
    module Link
      # target page number
      def page
        raise 'Override page with the actual page value to be a Page.'
      end
      # the link's href
      def url
        page_url_for page
      end
      # remote option
      def remote
        options[:remote]
      end
    end

    # A page
    class Page < Tag
      include Link
      # target page number
      def page
        options[:page]
      end
    end

    # Link with page number that appears at the leftmost
    class FirstPage < Tag
      include Link
      def page #:nodoc:
        1
      end
    end

    # Link with page number that appears at the rightmost
    class LastPage < Tag
      include Link
      def page #:nodoc:
        options[:total_pages]
      end
    end

    # The "previous" page of the current page
    class PrevPage < Tag
      include Link
      def page #:nodoc:
        options[:current_page] - 1
      end
    end

    # The "next" page of the current page
    class NextPage < Tag
      include Link
      def page #:nodoc:
        options[:current_page] + 1
      end
    end

    # Non-link tag that stands for skipped pages...
    class Gap < Tag
    end
  end
end
