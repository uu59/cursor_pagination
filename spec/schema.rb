ActiveRecord::Schema.define do
  create_table :plates, force: true do |t|
    t.string :name
    t.float :price

    t.timestamps
  end

  create_table :plate_categories, force: true do |t|
    t.belongs_to :plate
    t.string :name

    t.timestamps
  end
end