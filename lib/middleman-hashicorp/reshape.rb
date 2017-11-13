require 'base64'

class ReshapeMiddleware
  def initialize(app)
    @app = app
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
      # run the response body through node, decode from base64
      @response = [Base64.decode64(`node #{File.dirname(__FILE__)}/reshape/reshape.js < #{tempfile}`.match(/-------- OUTPUT --------\n(.*)\n------------------------/)[1])]

      # now we can remove the tempfile
      File.delete(tempfile)

      # ok let's return the modified response now
      puts "processed '#{path}' with reshape"
      puts $?
      return [200, {}, @response]
    else
      return [@status, @headers, @response]
    end
  end
end
