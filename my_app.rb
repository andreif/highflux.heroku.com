require 'sinatra/base'
require './note'
require 'redcarpet'
require 'haml'
require 'nokogiri'
require 'albino'
# require 'pygmentize' # worked only for cedar
require 'net/http'

Tilt.register 'markdown', Redcarpet
Tilt.register 'mkd',      Redcarpet
Tilt.register 'md',       Redcarpet

module MyApp
  class Application < Sinatra::Base
    
    # use Rack::Auth::Basic do |username, password|
    #   username == ENV['AUTH_LOGIN'] && password == ENV['AUTH_PASS']
    # end
    
    set :root, File.dirname(__FILE__)
    set :markdown, :layout_engine => :haml
    
    helpers do
      def render_markdown(text)
        options = [:hard_wrap, :filter_html, :autolink, :no_intraemphasis, :fenced_code, :gh_blockcode]
        Redcarpet.new(text, *options).to_html
      end

      def syntax_highlighter(html)
        doc = Nokogiri::HTML(html)
        doc.search("//pre[@lang]").each do |pre|
          #pre.replace Albino.colorize(pre.text.rstrip, pre[:lang])
          pre.replace Net::HTTP.post_form(
            URI.parse('http://pygments.appspot.com/'), {'code'=>pre.text.rstrip, 'lang'=>pre[:lang]}
          ).body
        end
        doc.to_s
      end
    end
    
    
    get '/' do
      @title = 'Notes'
      @notes = Note.all
      haml :index
    end
    
    get '/aboutme' do
      @title = 'About me'
      markdown :about
    end
    
    get '/:id.md' do
      if @note = Note.find(params[:id])
        content_type :text
        @note.body
      else
        status 404
        markdown :"404"
      end
    end
    
    get '/:id' do
      if @note = Note.find(params[:id])
        @title = @note.title
        haml :show
      else
        status 404
        markdown :"404"
      end
    end
  end
end
