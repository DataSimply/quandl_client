module Quandl
module Client

class Dataset
  
  include Concerns::Search
  include Concerns::Properties
  
  
  ##########  
  # SCOPES #
  ##########
  
  # SEARCH
  search_scope :query, :rows
  search_scope :page, ->(p){ where( page: p.to_i )}
  search_scope :source_code, ->(c){ where( code: c.to_s.upcase )}
  
  # SHOW
  scope_composer_for :show
  show_scope :rows, :exclude_data, :exclude_headers, :trim_start, :trim_end, :transform, :collapse
  show_helper :find, ->(id){ connection.where(attributes).find( id ) }
  show_helper :connection, -> { self.class.parent }
  
  
  ###############
  # ASSOCIATIONS #
  ###############
   
  def source
    @source ||= Source.find(self.source_code)
  end
  
  
  ###############
  # VALIDATIONS #
  ###############
  
  validates :code, presence: true, format: { with: /[A-Z0-9_]+/ }
  validates :name, presence: true, :length => { :maximum => 1000 }
  
  
  ##############
  # PROPERTIES #
  ##############
  
  attributes :source_code, :code, :name, :urlize_name, 
    :description, :updated_at, :frequency,
    :from_date, :to_date, :column_names, :private, :type,
    :display_url, :column_spec, :import_spec, :import_url,
    :locations_attributes, :data, :availability_delay, :refreshed_at
    
  before_save :enforce_required_formats
  
  alias_method :locations, :locations_attributes
  alias_method :locations=, :locations_attributes=
  
  def full_code
    @full_code ||= File.join(self.source_code, self.code)
  end

  def data_table
    Data::Table.new( raw_data )
  end
  
  def raw_data
    @raw_data ||= (self.data || Dataset.find(full_code).data || [])
  end
  
  protected
  
  def enforce_required_formats
    self.data = Quandl::Data::Table.new(data).to_csv
    self.locations_attributes = locations_attributes.to_json if locations_attributes.respond_to?(:to_json) && !locations_attributes.kind_of?(String)
  end
  
end

end
end