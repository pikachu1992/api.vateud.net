class Airport < ActiveRecord::Base
  attr_accessible :country_id, :icao, :major, :iata, :scenery_fs9_link, :scenery_fsx_link,
                  :scenery_xp_link, :description

  has_paper_trail

  validates :icao, :country_id, :iata, :presence => true
  validates :icao, :uniqueness => true
  validates_length_of :icao, :maximum => 4, :minimum => 4
  validates_length_of :iata, :maximum => 3, :minimum => 3

  belongs_to :country

  before_save :upcase_icao


  def upcase_icao
    self.icao = self.icao.upcase
  end

  def data
    Airdata::Airport.find_by_icao(self.icao.upcase)
  end

  def self.to_csv(options = {})
    columns = ["country_code", "country_name", "icao", "iata", "major", "scenery_fs9_link", "scenery_fsx_link",
                  "scenery_xp_link", "description", "name", "elevation", "ta", "msa", "lat", "lon"]
    CSV.generate(options) do |csv|
      csv << columns
      all.each do |airport|
        row = [airport.country.code, airport.country.name, airport.icao, airport.iata, airport.major,
          airport.scenery_fs9_link, airport.scenery_fsx_link, airport.scenery_xp_link, airport.description,
          airport.data.name, airport.data.elevation, airport.data.ta, airport.data.msa, airport.data.lat,
          airport.data.lon]
        csv << row
      end
    end
  end

  def to_csv_single(options = {})
    columns = ["country_code", "country_name", "icao", "iata", "major", "scenery_fs9_link", "scenery_fsx_link",
                  "scenery_xp_link", "description", "name", "elevation", "ta", "msa", "lat", "lon"]
    CSV.generate(options) do |csv|
      csv << columns
      airport = self
      row = [airport.country.code, airport.country.name, airport.icao, airport.iata, airport.major,
          airport.scenery_fs9_link, airport.scenery_fsx_link, airport.scenery_xp_link, airport.description,
          airport.data.name, airport.data.elevation, airport.data.ta, airport.data.msa, airport.data.lat,
          airport.data.lon]
      csv << row    
    end    
  end


  rails_admin do 
    navigation_label 'vACC Staff Zone'

    list do
      field :icao  do
        column_width 60
        pretty_value do          
          id = bindings[:object].id
          icao = bindings[:object].icao
          bindings[:view].link_to "#{icao}", bindings[:view].rails_admin.show_path('airport', id)
        end
      end
      field :iata do
        column_width 60
      end
      field :country
      field :major
      field :created_at
      field :updated_at
    end

    edit do
      field :icao
      field :iata
      field :country do
        associated_collection_cache_all true  
        associated_collection_scope do
          subdivision = bindings[:object]
          Proc.new { |scope|
            scope = scope.unscoped.where(eud: true).reorder('name ASC')
            # scope = scope.limit(30)
          }
        end
      end    
      field :major
      field :scenery_fs9_link
      field :scenery_fsx_link
      field :scenery_xp_link
      field :description, :rich_editor do
        config({
          :insert_many => true
        })
      end

    end #end of edit
  end #end of rails admin

end
