require 'sinatra/base'

module MyApp
  class Application < Sinatra::Base
    
    use Rack::Auth::Basic do |username, password|
      username == ENV['AUTH_LOGIN'] && password == ENV['AUTH_PASS']
    end
    
    configure do
    end
    
    get '/' do
      'Hello World'
    end
  end
end
