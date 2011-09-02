require 'sinatra/base'
require './note'
require 'haml'
require 'redcarpet'
require 'nokogiri'
# require 'albino'; require 'pygmentize' # worked only for cedar
require 'net/http'

Tilt.register 'markdown', Redcarpet
Tilt.register 'mkd',      Redcarpet
Tilt.register 'md',       Redcarpet

class String
  def to_my_utf8
    ::Iconv.conv('UTF-8', 'ISO-8859-1', self + ' ')[0..-2]
  end
end

module MyNotes
  class Application < Sinatra::Base
    
    configure do
      set :root, File.dirname(__FILE__)
      set :markdown, :layout_engine => :haml
      Mongoid.configure do |config|
        if ENV['MONGOHQ_URL']
          conn = Mongo::Connection.from_uri(ENV['MONGOHQ_URL'])
          uri = URI.parse(ENV['MONGOHQ_URL'])
          config.master = conn.db(uri.path.gsub(/^\//, ''))
        else
          config.master = Mongo::Connection.from_uri("mongodb://localhost:27017").db('test')
        end
      end
    end
    
    
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
      @notes = Note.order_by([:created_at, :desc]).all
      haml :index
    end
    
    get '/aboutme' do
      @title = 'About me'
      markdown :about
    end
    
    get '/update' do
      Note.fetch_from_github
      redirect to '/'
    end
    
    post '/update' do
      Note.fetch_from_github
      ''
    end
    
    get '/clear' do
      Note.delete_all
      redirect to '/'
    end
    
    get '/:id.md' do
      if @note = Note.find_by_param(params[:id])
        content_type :text
        @note.source
      else
        status 404
        markdown :"404"
      end
    end
    
    get '/:id' do
      if @note = Note.find_by_param(params[:id])
        @title = @note.title
        haml :show
      else
        status 404
        markdown :"404"
      end
    end
  end
end
