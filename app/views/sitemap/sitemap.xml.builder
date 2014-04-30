base_url = "https://#{request.host_with_port}"
xml.instruct! :xml, :version=>'1.0'
 
xml.tag! 'urlset', "xmlns" => "http://www.sitemaps.org/schemas/sitemap/0.9" do
 
  xml.url do
    xml.loc "#{base_url}"
    xml.changefreq "monthly"
    xml.priority 1.0
  end
 
  xml.url do
    xml.loc "#{base_url}/about"
    xml.lastmod Time.now.to_date
    xml.changefreq "monthly"
    xml.priority 1.0
  end
 
  xml.url do
    xml.loc "#{base_url}/explore"
    xml.lastmod Time.now.to_date
    xml.changefreq "monthly"
    xml.priority 1.0
  end
 
  xml.url do
    xml.loc "#{base_url}/enterprise"
    xml.lastmod Time.now.to_date
    xml.changefreq "monthly"
    xml.priority 1.0
  end
  
  xml.url do
    xml.loc "#{base_url}/team"
    xml.lastmod Time.now.to_date
    xml.changefreq "monthly"
    xml.priority 1.0
  end
 
  xml.url do
    xml.loc "#{base_url}/pricing"
    xml.lastmod Time.now.to_date
    xml.changefreq "monthly"
    xml.priority 1.0
  end
 
  xml.url do
    xml.loc "#{base_url}/terms_of_use"
    xml.lastmod Time.now.to_date
    xml.changefreq "monthly"
    xml.priority 1.0
  end
  
  xml.url do
    xml.loc "#{base_url}/faq"
    xml.lastmod Time.now.to_date
    xml.changefreq "monthly"
    xml.priority 1.0
  end
 
  @items.each do |item|
    xml.url do
      xml.loc "#{base_url}/collections/" + item.collection_id.to_s + "/items/" + item.id.to_s
      xml.lastmod item.updated_at.to_date
      xml.priority 0.9
    end
  end
 
  @collections.each do |collection|
    xml.url do
      xml.loc "#{base_url}/collections/" + collection.id.to_s
      xml.lastmod collection.updated_at.to_date
      xml.priority 0.9
    end
  end
 
end