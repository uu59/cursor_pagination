class Plate < ActiveRecord::Base
  has_many :plate_categories
end

class PlateCategory < ActiveRecord::Base
  belongs_to :plates
end