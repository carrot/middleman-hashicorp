# HashiCorp Middleman Customizations

A wrapper around [Middleman](https://middlemanapp.com/) for HashiCorp's customizations.

## Installation

Add this line to the Gemfile:

```ruby
gem 'middleman-hashicorp', git: 'https://github.com/carrot/middleman-hashicorp'
```

And then run:

```shell
$ bundle
```

## Usage

To generate a new site, follow the instructions in the [Middleman docs](http://middlemanapp.com/basics/getting-started/). Then add the following line to your `config.rb`:

```ruby
activate :hashicorp
```

If you are a HashiCorp employee and are deploying a HashiCorp middleman site, you will probably need to set some options. Here is an example from Packer:

```ruby
activate :hashicorp do |h|
  h.name        = "packer"
  h.version     = "0.7.0"
  h.github_slug = "hashicorp/terraform"

  # Disable fetching release information - this is useful for non-product site
  # or local development.
  h.releases_enabled = false

  # Optional (shown with defaults)
  # h.minify_javascript = false
  # h.minify_css = false
  # h.hash_assets = false
  # h.reshape_component_file = 'assets/reshape.js'
  # h.reshape_asset_root = 'assets'
  # h.reshape_source_path = 'public'
  # h.datocms_api_key = nil
  # h.segment_production_key = '0EXTgkNx0Ydje2PGXVbRhpKKoe5wtzcE' #HahiCorp staging key
end
```

Almost all other Middleman options may be removed from the `config.rb`. See a HashiCorp project for examples.

Now just run:

```shell
$ middleman server
```

and you are off running!

## Customizations

### Default Options

* Syntax highlighting (via [middleman-syntax](https://github.com/middleman/middleman-syntax) is automatically enabled
* Asset directories are organized like Rails:
  * `assets/stylesheets`
  * `assets/javascripts`
  * `assets/images`
  * `assets/fonts`
* The Markdown engine is redcarpet (see the section below on Markdown customizations)
* Reshape defaults:
  * Asset root: `'assets'`
  * Asset source root: `'public'`
  * Component file: `'assets/reshape.js'`

### Inline SVGs

> **Note:** Temporarily out of commission

Getting SVGs out of the asset pipeline and into the DOM can be hard, but not
with the magic `inline_svg` helper!

```erb
<%= inline_svg "my-asset.svg" %>
```

It supports configuring the class, height, width, and viewbox.

### Helpers

* `latest_version` - get the version specified in `config.rb` as `version`, but replicated here for use in views.

  ```ruby
  latest_version #=> "1.0.0"
  ```

* `system_icon` - use vendored image assets for a system icon

  ```ruby
  system_icon(:windows) #=> "<img src=\"/images/icons/....png\">"
  ```

* `pretty_os` - get the human name of the given operating system

  ```ruby
  pretty_os(:darwin) => "Mac OS X"
  ```

* `pretty_arch` - get the arch out of an arch

  ```ruby
  pretty_arch(:amd64) #=> "64-bit"
  ```

### Markdown

This extension extends the redcarpet markdown processor to add some additional features:

* Autolinking of URLs
* Fenced code blocks
* Tables
* TOC data
* Strikethrough
* Superscript

In addition to "standard markdown", the custom markdown parser supports the following:

#### Auto-linking Anchor Tags

Since the majority of HashiCorp's projects use the following syntax to define APIs, this extension automatically converts those to named anchor links:

```markdown
* `api_method` - description
```

Outputs:

```html
<ul>
  <li><a name="api_method" /><a href="#api_method"></a> - description</li>
</ul>
```

#### Auto-linking Header Tags

Header links will automatically generate linkable hrefs on hover. This can be used to easily link to sub-sections of a page. This _requires_ the following SCSS.

```scss
// assets/stylesheets/application.scss
@import 'hashicorp/anchor-links';
```

Any special characters are converted to an underscore (`_`).

#### Recursive Markdown Rendering

By default, the Markdown spec does not call for rendering markdown recursively inside of HTML. With this extension, it is valid:

```markdown
<div class="center">
  This will **be bold**!
</div>
```

## Contributing

1.  [Fork it](https://github.com/hashicorp/middleman-hashicorp/fork)
2.  Create your feature branch (`git checkout -b my-new-feature`)
3.  Commit your changes (`git commit -am 'Add some feature'`)
4.  Push to the branch (`git push origin my-new-feature`)
5.  Create a new Pull Request
