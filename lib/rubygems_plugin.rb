# install node modules
Gem.post_install do
  `cd #{File.dirname(__FILE__)}/middleman-hashicorp/reshape && npm i`
  puts "post_install called for carrot/middleman-hashicorp"
end
