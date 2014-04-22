module Feedzirra
 
  module Parser
    # Parser for dealing with RDF feed entries.
    class MediaRSSEntry
      include SAXMachine
      include FeedEntryUtilities
 
      element :title
      element :link, :as => :url
      
      element :"dc:creator", :as => :author
      element :author, :as => :author
      element :"content:encoded", :as => :content
      element :description, :as => :summary
  
      # element :"media:content", :as => :image, :value => :url
      element :"itunes:image", :as => :image, :value => :href
      element :pubDate, :as => :published
      element :pubdate, :as => :published
      element :"dc:date", :as => :published
      element :"dc:Date", :as => :published
      element :"dcterms:created", :as => :published
      
      
      element :"dcterms:modified", :as => :updated
      element :issued, :as => :published
      elements :category, :as => :categories
      
      element :guid, :as => :entry_id
 
      element :"media:rating", :as => :media_rating, :class => MediaRSSScheme
      element :"media:title", :as => :media_title, :class => MediaRSSText
      element :"media:description", :as => :media_description, :class => MediaRSSText
      element :"media:keywords", :as => :media_keywords
      element :"media:player", :as => :media_player, :class => MediaRSSThumbnail
      element :"media:copyright", :as => :media_copyright, :class => MediaRSSCopyright
      element :"media:restriction", :as => :media_restriction, :class => MediaRSSRestriction
      element :"media:embed", :as => :media_embed, :class => MediaRSSEmbed
 
      elements :"media:content", :as => :media_contents, :class => MediaRSSContent
      elements :"media:thumbnail", :as => :media_thumbnails, :class => MediaRSSThumbnail
      elements :"media:credit", :as => :media_credits, :class => MediaRSSScheme
 
      elements :"media:comment", :as => :media_comments
      elements :"media:response", :as => :media_responses
      elements :"media:backLink", :as => :media_back_links
 
      element :"media:hash", :as => :media_hash_md5, :with => { :algo => 'md5' }
      element :"media:hash", :as => :media_hash_sha1, :with => { :algo => 'sha1' }
      
    end
 
  end
 
end