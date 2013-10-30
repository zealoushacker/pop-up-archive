class Geolocation < ActiveRecord::Base
  attr_accessible :name
  before_save :generate_slug, on: :create
  has_many :items

  geocoded_by :name

  if Rails.env.test?
    after_save :enqueue_geocode
  else
    after_commit :enqueue_geocode
  end

  def self.for_name(string)
    find_by_slug slugify string or create name: string
  end

  def to_indexed_json
    {
      name: name,
      position: {
        lat: latitude,
        lon: longitude
      }
    }
  end

  private

  def generate_slug
    self.slug = self.class.slugify name
  end

  def self.slugify(string)
    string.downcase.gsub(/\W/,'')
  end

  # this makes tests much faster
  def enqueue_geocode
    if name_changed?
      if Rails.env.test?
        update_attributes({
          latitude:   42.373987,
          longitude: -71.121172
          }, without_protection: true) if latitude.blank?
      else
        GeocodeWorker.perform_async(id) unless Rails.env.test?
      end
    end
  end
end
