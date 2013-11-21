object nil


node(:DEBUG) { true } if @debug
node(:facets) { @search.facets }
node(:total_hits) { @search.total }
node(:max_score) { @search.max_score }
node(:page) { ((@search.options[:from] || 0) / RESULTS_PER_PAGE) + 1 }
node(:query) { params[:query] }

child @search.results do

  attribute :id
  attribute :title, if: ->(o) { o.title.present? }
  attribute :description, if: ->(o) { o.description.present? }
  attribute :date_created, if:  ->(o) { o.date_created.present? }
  attribute :identifier, if: ->(o) { o.identifier.present? }
  attribute :collection_id, if: ->(o) { o.collection_id.present? }
  attribute :collection_title, if: ->(o) { o.collection_title.present? }
  attribute :episode_title, if: ->(o) { o.episode_title.present? }
  attribute :series_title, if: ->(o) { o.series_title.present? }
  attribute :date_broadcast, if: ->(o) { o.date_broadcast.present? }
  attribute :tags, if: ->(o) { o.tags.present? }
  attribute :notes, if: ->(o) { o.notes.present? }
  attribute(:date_added, if: ->(o) { o.date_added.present? }) {|o| o.created_at }

  child :audio_files do
    attributes :url, :filename, :id
  end

  child(:entities, if: ->(o) { o.entities.present? }) do |e|
    extends 'api/v1/entities/entity'
  end

  node(:highlights, if: ->(o) { o.highlighted_audio_files.present? }) do |i|
    { audio_files: (i.highlighted_audio_files.map do |af|
      {
        url: af.url,
        filename: af.filename,
        id: af.id
      }
    end) }
  end
end