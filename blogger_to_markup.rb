require 'rubygems'
require 'nokogiri'
require 'fileutils'

class Article
  attr_reader :title, :author, :date, :content
  def initialize(title, author, date, content)
    @title = title
    @author = author
    @date = date.split('T').first.gsub('-', '/')
    set_content(content)
  end
  
  def set_content(content)
    @content = content.gsub('<br />', "\n").gsub('&#39;', '\'').
      gsub('<p>', "\n\n").
      gsub(/<span style="font-style: italic;">(.+?)<\/span>/, '_\1_').
      gsub(/<em>(.+?)<\/em>/, '_\1_').
      gsub(/<tt>(.+?)<\/tt>/, '<code>\1</code>').
      gsub(/<strong>(.+?)<\/strong>/, '__\1__').
      gsub(/<\/ul>|<\/ol>|<\/li>|<\/?span.*?>|<\/p>|<\/?blockquote>/, '').
      gsub('<li>', "\n* ").
      gsub(/<ul>|<ol>/, "\n").
      gsub(/<a href="(.+?)".*?>(.+?)<\/a>/, '[\2](\1)').
      gsub(/<a onblur.+?><img .*? src="(.+?)" .*?\/><\/a>/, '![](\1)').
      gsub(/<h(.)>(.+?)<\/h.>/, "\n\2")
  end
  
  def to_s
    "title: \"#{@title}\"\nauthor: \"#{@author}\"\ndate: #{@date}\n\n#{@content}\n\n"
  end
  
  # filename compatible with default toto filename
  def filename
    "#{@date.gsub('/', '-')}-#{@title.gsub(/\s/, '-').gsub(/[,:)(.=><>!\/'`#]/,'').downcase}.txt"
  end
  
end

f = File.open(ARGV.first)
doc = Nokogiri::XML(f)

articles = []

doc.css('entry').each do |entry|
  next if entry.at_css('category')['term'] !~ /post$/ # skip comments etc.
  title = entry.at_css('title').content
  author = entry.at_css('author name').content
  date = entry.at_css('published').content
  content = entry.at_css("content").content
  articles << Article.new(title, author, date, content)
end

FileUtils.mkdir_p('articles')

articles.each do |article|
  f = File.open('articles/'+article.filename, 'w')
  f.write article.to_s
  f.close
end

puts "Done."
