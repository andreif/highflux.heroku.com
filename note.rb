require 'mongoid'
require './git_hub'
require 'redcarpet'
require 'nokogiri'
# require 'albino'; require 'pygmentize' # worked only for cedar
require 'net/http'


class Note
  include Mongoid::Document
  
  field :title, type: String
  field :path, type: String
  field :source, type: String
  field :html, type: String
  field :sha, type: String
  field :created_at, type: DateTime
  field :modifed_at, type: DateTime
  
  
  def self.fetch_from_github
    GitHub.config(user: 'andreif', repo: 'notes', ref: 'master').root_files(/^\d{4}.+\.md$/).collect do |hash|
      next if Note.where(path: hash['path'], sha: hash['sha']).exists?
      Note.where(path: hash['path']).delete
      Note.create(
        title: get_title(hash),
        path: hash['path'],
        sha: hash['sha'],
        source: hash['content'],
        html: render(hash['content']),
        created_at: DateTime.parse(hash['path'][0..10]),
        modified_at: Time.now
      )
    end
  end
  
  def self.find_by_param url
    where(path: url+'.md').first
  end
  
  def self.get_title hash
    if hash['content'].strip =~ /^\# ([^\n]+)/
      $1
    else
      hash['path'].gsub(/\.md$/,'').gsub('-',' ')[11..-1]
    end
  end
  
  def to_param
    path.gsub(/\.md$/,'')
  end
  
  def self.render text
    text = text[$1.length..-1] if text =~ /^(\s*\# [^\n]+)/
    options = [:autolink, :no_intraemphasis, :fenced_code, :gh_blockcode] # http://rubydoc.info/gems/redcarpet/1.17.2/Redcarpet
    html = Redcarpet.new(text, *options).to_html
    doc = Nokogiri::HTML(html)
    doc.search("//pre[@lang]").each do |pre|
      #pre.replace Albino.colorize(pre.text.rstrip, pre[:lang])
      if body = Net::HTTP.post_form(
        URI.parse('http://pygments.appspot.com/'), {'code'=>pre.text.rstrip, 'lang'=>pre[:lang]}
      ).body
        pre.replace body
      end
    end
    doc.to_s
  end
end
