require "spec_helper"
require_relative "../lib/cursor_pagination.rb"

RSpec.describe CursorPagination do
  before :all do 
    Plate.create(name: "tostones", price: 1)
    Plate.create(name: "mamposteao", price: 2)
    Plate.create(name: "mofongo", price: 3)
    Plate.create(name: "pollo al horno", price: 4)
    Plate.create(name: "carne frita", price: 5)
    Plate.create(name: "churrasco", price: 6)

    Plate.where(name: ["tostones", "mamposteao", "mofongo"]).each do |plate|
      plate.plate_categories.create(name: "side")
    end

    Plate.where(name: ["pollo al horno", "carne frita", "churrasco"]).each do |plate|
      plate.plate_categories.create(name: nil)
    end
  end

  describe "fetches the first page" do
    it "when paginating over a joined column" do
      query = Plate.includes(:plate_categories).limit(3)

      first_page = CursorPagination.new(
        anchor_column: "plate_categories.name",
        anchor_id: nil,
        anchor_value: nil,
        ar_relation: query,
        path_helper: lambda do |anchor_column:, anchor_id:, anchor_value:|
          "/api/plate_categories?anchor_column=#{anchor_column}&anchor_value=#{anchor_value}&anchor_id=#{anchor_id}"
        end,
        sort_direction: "desc"
      )

      # The page should be composed of the plates that have a set category because:
      #   * We are sorting over a nullable column and null values come last in descending order in MySQL.
      target_plates_ids = PlateCategory.where.not(name: nil).map(&:plate_id)
      
      expect(first_page.resources.length).to eq(3)
      
      first_page.resources.each do |resource|
        expect(target_plates_ids).to include(resource.id)
      end
    end
  end

  describe "fetches the second page" do
    it "when paginating over a joined column" do
      query = Plate.includes(:plate_categories).limit(3)
      
      first_page = CursorPagination.new(
        anchor_column: "plate_categories.name",
        anchor_id: nil,
        anchor_value: nil,
        ar_relation: query,
        path_helper: lambda do |anchor_column:, anchor_id:, anchor_value:|
          "/api/plate_categories?anchor_column=#{anchor_column}&anchor_value=#{anchor_value}&anchor_id=#{anchor_id}"
        end,
        sort_direction: "desc"
      )

      second_page = CursorPagination.new(
        anchor_column: "plate_categories.name",
        anchor_id: first_page.resources.last["id"],
        anchor_value: first_page.resources.last.plate_categories.first.name,
        ar_relation: query,
        path_helper: lambda do |anchor_column:, anchor_id:, anchor_value:|
          "/api/plate_categories?anchor_column=#{anchor_column}&anchor_value=#{anchor_value}&anchor_id=#{anchor_id}"
        end,
        sort_direction: "desc"
      )

      # The second page should be composed of the plates that have null category because:
      #   * We are sorting over a nullable column and null values come last in descending order in MySQL.
      #     The first page has all the records with set category.
      target_plates_ids = PlateCategory.where(name: nil).map(&:plate_id)
      
      expect(second_page.resources.length).to eq(3)
      
      second_page.resources.each do |resource|
        expect(target_plates_ids).to include(resource.id)
      end
    end
  end
end
