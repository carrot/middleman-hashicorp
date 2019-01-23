module Middleman
  module HashiCorp
    require_relative "redcarpet"
    require_relative "releases"
    require_relative "rouge"
    require_relative "reshape"
    require "cgi"
  end
end

class Middleman::HashiCorpExtension < ::Middleman::Extension
  option :name, nil, "The name of the package (e.g. 'consul')"
  option :version, nil, "The version of the package (e.g. 0.1.0)"
  option :minify_javascript, false, "Whether to minimize JS or not"
  option :minify_css, false, "Whether to minimize CSS or not"
  option :hash_assets, false, "Whether to hash assets or not"
  option :github_slug, nil, "The project's GitHub namespace/project_name duo (e.g. hashicorp/serf)"
  option :website_root, "website", "The project's middleman directory relative to the Git root"
  option :releases_enabled, true, "Whether to fetch releases"
  option :reshape_component_file, 'assets/reshape.js', "Path to reshape component import file"
  option :reshape_asset_root, 'assets', "Root for CSS, JS and other assets"
  option :reshape_source_path, 'public', "Folder where compiled assets are available"
  option :datocms_api_key, nil, "API key for DatoCMS, if present activates Dato"

  def initialize(app, options_hash = {}, &block)
    super

    return if app.mode?(:config)

    # Grab a reference to self so we can access it deep inside blocks
    _self = self

    # Use syntax highlighting on fenced code blocks
    # This is super hacky, but middleman does not let you activate an
    # extension on "app" outside of the "configure" block.
    require "middleman-syntax"
    syntax = Proc.new { activate :syntax }
    app.configure(:development, &syntax)
    app.configure(:build, &syntax)

    if (options.datocms_api_key)
      require "middleman-dato"
      app.activate :dato,
        token: options.datocms_api_key,
        preview: ENV['ENV'] != 'production'
    end

    # Organize assets like Rails
    app.config[:css_dir] = "assets/stylesheets"
    app.config[:js_dir] = "assets/javascripts"
    app.config[:images_dir] = "assets/images"
    app.config[:fonts_dir] = "assets/fonts"

    # Make custom assets available
    # TODO: fix this, sprockets no longer used
    # assets = Proc.new { sprockets.import_asset "ie-compat.js" }
    # app.configure(:development, &assets)
    # app.configure(:build, &assets)

    # Override the default Markdown settings to use our customer renderer
    # and the options we want!
    app.config[:markdown_engine] = :redcarpet
    app.config[:markdown] = Middleman::HashiCorp::RedcarpetHTML::REDCARPET_OPTIONS.merge(
      renderer: Middleman::HashiCorp::RedcarpetHTML
    )

    # Do not strip /index.html from directory indexes
    app.config[:strip_index_file] = false

    # Set the latest version
    app.config[:latest_version] = options.version

    # Do the releases dance
    app.config[:product_versions] = _self.product_versions

    app.config[:github_slug] = options.github_slug
    app.config[:website_root] = options.website_root

    app.config[:reshape_component_file] = options.reshape_component_file
    app.config[:reshape_asset_root] = options.reshape_asset_root
    app.config[:reshape_source_path] = options.reshape_source_path
    app.config[:datocms_api_key] = options.datocms_api_key

    # !!!
    # This is making things slower with the component library, commented out
    # for now
    # !!!

    # Configure the development-specific environment
    # app.configure :development do
    #   # Reload the browser automatically whenever files change
    #   require "middleman-livereload"
    #   activate :livereload,
    #     host: "0.0.0.0",
    #     ignore: [/img/]
    # end

    # Configure the build-specific environment
    minify_javascript = options.minify_javascript
    minify_css = options.minify_css
    hash_assets = options.hash_assets

    app.configure :build do

      if minify_css
        # Minify CSS on build
        activate :minify_css
      end

      if minify_javascript
        # Minify Javascript on build
        activate :minify_javascript
      end

      if hash_assets
        # Enable cache buster
        activate :asset_hash
      end
    end
  end

  def after_configuration
    # Middleware for rendering preact components
    @app.use ReshapeMiddleware, component_file: options.reshape_component_file

    # compile js with webpack, css with postcss
    @app.activate :external_pipeline,
      name: options.reshape_asset_root,
      command: "cd assets && NODE_ENV=#{ENV['ENV'] || 'development'}  ./node_modules/.bin/spike #{@app.build? ? :compile : :watch}",
      source: "#{options.reshape_asset_root}/#{options.reshape_source_path}"
  end

  helpers do
    # Encodes dato data as unicode-escaped, base64'd JSON for compatibility with
    # reshape components. Handles arrays, strings, and hashes only right now.
    def encode(data)
      # convert from dato classes into json
      if data.is_a?(Array)
        res = "[#{data.map { |d|
          d.is_a?(String) ? d.to_json : d.to_hash.to_json
        }.join(',')}]"
      elsif data.is_a?(String)
        res = data.to_json
      else
        res = data.to_hash.to_json
      end
      # apply escaping for unicode chars
      res = URI.escape(res, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
        .gsub(/%([0-9A-F]{2})/) { |m| "0x#{$1}".hex.chr(Encoding::UTF_8) }
      # encode to base64
      Base64.encode64(res).gsub(/\n/, '')
    end

    # Replace dato meta tags with custom overrides
    # Works for <meta> and <title> tags only.
    # Overrides is a hash of tags and values to override
    # e.g
    # {
    #   "description" => "this is the description content",
    #   "og:title" => "this is the title content"
    # }
    # Page is the current dato object (page, post etc.)
    def custom_meta_tags(overrides, page)
      dato_tags = dato_meta_tags(page)
      # If <title> is provided as an override, replace
      if overrides.keys.include?("title")
        dato_tags.sub!(/<title>(.*?)<\/title>/, "<title>#{overrides['title']}</title>")
      end
      split_by = '<meta '

      # step through each dato-generated meta tag
      new_tags = dato_tags.split(split_by).inject([]) do |acc, tag|
        # get the tag's name/property value
        name = tag.match(/^(?:property|name)="(.*?)"/)
        # if the tag's name matches one of the override names, replace it
        if (name && overrides.keys.include?(name[1]))
          tag_type = name.to_s.include?('og:') ? 'property' : 'name'
          acc.push("#{tag_type}=\"#{CGI::escapeHTML(name[1])}\" content=\"#{CGI::escapeHTML(overrides[name[1]])}\" />")
        else
          # otherwise, leave the tag as-is
          acc.push(tag)
        end
        # and return the accumulator
        acc
      end

      new_tags.join(split_by)
    end

    # Markdown render helper function
    def md(text)
      Redcarpet::Markdown.new(Middleman::HashiCorp::RedcarpetHTML, Middleman::HashiCorp::RedcarpetHTML::REDCARPET_OPTIONS).render(text)
    end

    # Get the title for the page.
    def title_for(page)
      if page && page.data.page_title
        return "#{page.data.page_title} - HashiCorp"
      end
      "HashiCorp"
    end

    # Get the description for the page
    def description_for(page)
      description = (page.data.description || page.metadata[:description] || "")
        .gsub('"', '')
        .gsub(/\n+/, ' ')
        .squeeze(' ')

      return escape_html(description)
    end

    # Returns the id for this page.
    def body_id_for(page)
      if page.url == "/" || page.url == "/index.html"
        return "p-home"
      end
      if !(title = page.data.page_title || page.metadata[:title]).blank?
        return "p-" + title
          .downcase
          .gsub('"', '')
          .gsub(/[^\w]+/, '-')
          .gsub(/_+/, '-')
          .squeeze('-')
          .squeeze(' ')
      end
      return ""
    end

    #
    # Generate an inline svg from the given asset name.
    #
    # @option options [String] :class
    # @option options [String] :width
    # @option options [String] :height
    #
    # @return [String]
    #
    def inline_svg(filename, options = {})
      asset = File.open(File.join(Middleman::Application.root, "/assets/img/#{filename}"), "r:utf-8").read

      # If the file wasn't found, embed error SVG
      if asset.nil?
        %(
          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 30"
            width="400px" height="30px"
          >
            <text font-size="16" x="8" y="20" fill="#cc0000">
              Error: '#{filename}' could not be found.
            </text>
            <rect
              x="1" y="1" width="398" height="28" fill="none"
              stroke-width="1" stroke="#cc0000"
            />
          </svg>
        )

      # If the file was found, parse it, add optional classes, and then embed it
      else
        file = asset
        doc = Nokogiri::HTML::DocumentFragment.parse(file)
        svg = doc.at_css("svg")

        if options[:class].present?
          svg["class"] = options[:class]
        end

        if options[:width].present?
          svg["width"] = options[:width]
        end

        if options[:height].present?
          svg["height"] = options[:height]
        end

        doc
      end
    end

    #
    # Output an image that corresponds to the given operating system using the
    # vendored image icons.
    #
    # @return [String] (html)
    #
    def system_icon(name, options = {})
      inline_svg("icons/icon_#{name.to_s.downcase}.svg", {
        height: 75,
        width: 75,
      }.merge(options))
    end

    #
    # The formatted operating system name.
    #
    # @return [String]
    #
    def pretty_os(os)
      case os
      when /darwin/
        "Mac OS X"
      when /freebsd/
        "FreeBSD"
      when /openbsd/
        "OpenBSD"
      when /netbsd/
        "NetBSD"
      when /linux/
        "Linux"
      when /windows/
        "Windows"
      else
        os.capitalize
      end
    end

    #
    # The formatted architecture name.
    #
    # @return [String]
    #
    def pretty_arch(arch)
      case arch
      when "all"
        "Universal (32 and 64-bit)"
      when "i686", "i386", "686", "386"
        "32-bit"
      when "x86_64", "86_64", "amd64"
        "64-bit"
      when /\-/
        parts = arch.split("-", 2)
        "#{pretty_arch(parts[0])} (#{parts[1]})"
      else
        parts = arch.split("_")

        if parts.empty?
          raise "Could not determine pretty arch `#{arch}'!"
        end

        parts.last.capitalize
      end
    end

    #
    # Calculate the architecture for the given filename.
    #
    # @return [String]
    #
    def arch_for_filename(path)
      file = File.basename(path, File.extname(path))

      case file
      when /686/, /386/
        "32-bit"
      when /86_64/, /amd64/
        "64-bit"
      else
        parts = file.split("_")

        if parts.empty?
          raise "Could not determine arch for filename `#{file}'!"
        end

        parts.last.capitalize
      end
    end

    #
    # Return the GitHub URL associated with the project
    # @return [String] the project's URL on GitHub
    # @return [false] if github_slug hasn't been set
    #
    def github_url(specificity = :repo)
      # TODO: this is causing a huge error for some reason
      return false if github_slug.nil?
      base_url = "https://github.com/#{github_slug}"
      if specificity == :repo
        base_url
      elsif specificity == :current_page
        base_url + "/blob/master/" + path_in_repository(current_page)
      end
    end

    #
    # Return a resource's path relative to its source repo's root directory.
    # @param page [Middleman::Sitemap::Resource] a sitemap resource object
    # @return [String] a resource's path relative to its source repo's root
    # directory
    #
    def path_in_repository(resource)
      relative_path = resource.path.match(/.*\//).to_s
      file = resource.source_file.split("/").last
      website_root + "/source/" + relative_path + file
    end

    #
    # Query the API to get the latest version of a given terraform provider
    #
    def latest_provider_version(name)
      Middleman::HashiCorp::Releases.fetch_latest_version("terraform-provider-#{name}")[:version]
    end
  end

  #
  # Query the API to get the real product download versions.
  #
  # @return [Hash]
  #
  def product_versions
    if options.releases_enabled
      Middleman::HashiCorp::Releases.fetch(options.name, options.version)
    else
      {
        "HashiOS" => {
          "amd64" => "/0.1.0_hashios_amd64.zip",
          "i386" => "/0.1.0_hashios_i386.zip",
        }
      }
    end
  end
end
