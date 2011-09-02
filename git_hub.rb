require 'singleton'
require 'open-uri'
require 'json'
require 'base64'

class GitHub
  include Singleton
  
  def self.config hash
    @@user = hash[:user]
    @@repo = hash[:repo]
    @@ref  = hash[:ref]
    return self
  end
  
  def self.api_root
    "https://api.github.com/repos/#{@@user}/#{@@repo}/git"
  end
  
  def self.raw_root
    "https://raw.github.com/#{@@user}/#{@@repo}/#{@@ref}"
  end
  
  def self.get_tree ref
    if json = open("#{api_root}/trees/#{ref}").read
      if hash = JSON.parse(json)
        hash['tree']
      end
    end rescue nil
  end
  
  def self.get_blob ref
    if json = open("#{api_root}/blobs/#{ref}").read
      if hash = JSON.parse(json)
        if hash['encoding'] == 'base64'
          Base64.decode64(hash['content'])
        end
      end
    end rescue nil
  end
  
  def self.raw_blob path
    # https://raw.github.com/andreif/notes/master/2011-09-01-Trying-out-a-file-based-blog.md
    open(raw_root + '/' + path).read
  end
  
  def self.root_files mask = /.+/
    get_tree(@@ref).collect do |hash|
      # p hash
      if hash['type'] == 'blob' and hash['path'] =~ mask
        if hash['content'] = get_blob(hash['sha'])
          hash
        end
      end
    end.compact
  end
end

# GitHub.config(user:'andreif', repo:'notes', ref:'master').root_files.each do |hash|
#   p hash['sha']
# end
