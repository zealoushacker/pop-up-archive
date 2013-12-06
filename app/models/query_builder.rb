class QueryBuilder
  attr_accessor :params, :current_user

  def initialize(params, current_user)
    @params = params
    @current_user = current_user
  end

  def query
    if query_string
      yield QueryString.new(query_string)
    end
  end

  def facets
    facet_params.map do |name, details|
      Facet.new(name, details, filters).tap do |facet|
        yield facet if block_given?
      end
    end
  end

  def filters
    @_filters ||= filter_params.map {|name, details| Filter.new(name, details) } + [current_user_filter]
    (@_totalFilter ||= [AndFilter.new(@_filters)]).tap do |filter|
      yield filter[0] if block_given? && filter[0].present?
    end
  end

  private

  def query_string
    params[:query]
  end

  def sort_column
    params[:sort_by] || :date_created
  end

  def sort_order
    params[:sort_order] || 'desc'
  end

  def facet_params
    if params[:facets].present?
      params[:facets]
    elsif params[:facet].present?
      if params[:facet].kind_of? String
        {params[:facet] => {}}
      else
        {params[:facet].delete(:name) => params[:facet]}
      end
    else
      default_facets
    end
  end

  def filter_params
    (params[:filters] || {})
  end

  def current_user_filter
    if current_user.present?
      OrFilter.new([Filter.new(:collection_id, type: 'terms', value: current_user.searchable_collection_ids), public_filter])
    else
      public_filter
    end
  end

  def public_filter
    Filter.new(:is_public, type:'term', value: 'true')
  end

  def default_facets
    {date_created: {type:'date'}, date_broadcast: {type:'date'}, date_added: {type:'date'}, duration: {type:'histogram'}, interviewer:{}, interviewee:{}, tag:{}, collection_id:{}, creator:{}, host:{}, producer:{}, guest:{}}
  end
end
