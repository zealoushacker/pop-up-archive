class Person < ActiveRecord::Base
  attr_accessible :name
  before_save :generate_slug, on: :create
  has_many :contributions, dependent: :destroy
  has_many :items, through: :contributions

  include Tire::Model::Callbacks
  include Tire::Model::Search

  index_name { ENV['PEOPLE_INDEX_NAME'] || 'people' }

  settings  analysis: {
              filter: {
                ngram_filter: {
                  type: "edgeNGram",
                  min_gram: 2,
                  max_gram: 8,
                  side: "front"
                }
              },
              analyzer: {
                index_ngram_analyzer: {
                  type: "custom",
                  tokenizer: "standard",
                  filter: ["lowercase", "ngram_filter"]
                },
                search_ngram_analyzer: {
                  type: "custom",
                  tokenizer: "standard",
                  filter: ["standard", "lowercase", "ngram_filter"]
                }
              }
            } do
    mapping do
      indexes :id, index: :not_analyzed
      indexes :name, type: 'string', index_analyzer: 'index_ngram_analyzer', search_analyzer: 'search_ngram_analyzer'
      indexes :collection_id, type: 'string', as: 'collection_ids', index_name: 'collection_id'
    end
  end

  def self.search_within_collection(collection_id, query)
    Person.search do
      query { string "name:#{query}" }
      filter :terms, collection_id:[collection_id.to_i]
    end
  end


  def collection_ids
    items.collect{|i| i.collection_id}.uniq
  end

  def self.for_name(string)
    find_by_slug slugify string or create name: string
  end

  def as_json(params={})
    name.as_json
  end

  private

  def generate_slug
    self.slug = self.class.slugify name
  end

  def self.slugify(string)
    string.downcase.gsub(/\W/,'')
  end

end
