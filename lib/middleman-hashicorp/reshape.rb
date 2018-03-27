require 'base64'

class ReshapeMiddleware
  def initialize(app, options = {})
    @app = app
    @options = options
  end

  def call(env)
    @status, @headers, @response = @app.call(env)
    path = env['PATH_INFO']
    raw_path = /\/[a-zA-Z\-_\/]*?[^.]*$/.match(env['PATH_INFO'])
    html_path = /\.html$/.match(env['PATH_INFO'])
    if (raw_path or html_path)
      # write a tempfile to avoid going over bash argument length limit
      # encode with base64 to avoid weird bash arg stuff
      tempfile = "tmp-#{('a'..'z').to_a.shuffle[0,8].join}"
      File.write(tempfile, @response.body.join(''))

      component_file = "#{Dir.pwd}/#{@options[:component_file]}"
      # run the response body through node, decode from base64
      @response = [Base64.decode64(`node #{File.dirname(__FILE__)}/reshape/reshape.js < #{tempfile} #{component_file}`.match(/-------- OUTPUT --------\n(.*)\n------------------------/)[1])]

      # now we can remove the tempfile
      File.delete(tempfile)

      # ok let's return the modified response now
      puts "processed '#{path}' with reshape"
      puts $?
      return [200, {'Content-Type'=> 'text/html'}, @response]
    else
      return [@status, @headers, @response]
    end
  end
end
