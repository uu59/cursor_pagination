class CursorPagination
  ASC = "asc"
  COMPARATOR_INTERNAL_BUG = "sort_direction input has an unexpected value. Contact CursorPagination mantainer for support."
  DESC = "desc"
  GREATER_THAN_OPERATOR = ">"
  LESS_THAN_OPERATOR = "<"
  PAGE_SIZE = 3 # TODO: remove since it's a caller concern.

  # @param [String] anchor_column - Field to paginate on.
  # @param [String|Number|nil] anchor_value - Value of the anchor_column for the record to paginate from.
  # @param [ActiveRecord::Relation] ar_relation - Resource collection to paginate.
  # @param [String] sort_direction - Order of the pagination. Valid values: CursorPagination::ASC, CursorPagination::DESC.
  # @param [Proc] path_helper - Function that generates the next page link. This function should have any state that's not relevant to pagination partially applied.
  # @param [Number] anchor_id - ID of the record to paginate from.
  def initialize(anchor_column:, anchor_value:, ar_relation:, sort_direction:, path_helper:, anchor_id:)
    # To be used outside dynamic SQL statements.
    @anchor_column = anchor_column

    # To be used in dynamic SQL queries.
    @sql_anchor_column = ActiveRecord::Base.connection.quote_column_name(anchor_column)

    @anchor_value = anchor_value

    @ar_relation = ar_relation

    # Always select id to use it as secondary sort to prevent non-deterministic ordering when primary sort is on a non-unique column.
    unless primary_key_selected?(@ar_relation)
      raise Exception::PrimaryKeyNotSelected, "The provided ActiveRecord::Relation does not have the primary key selected. Cursor pagination requires a primary key to paginate undeterministic columns."
    end

    @sort_direction = sort_direction
    @path_helper = path_helper
    @anchor_id = anchor_id

    unless [CursorPagination::ASC, CursorPagination::DESC].include?(@sort_direction)
      raise Exception::InvalidSortDirection, "The provided order is not supported. Supported order values are: '#{ASC}', '#{DESC}'"
    end
  end

  def resources
    # Memoize expensive querying.
    return @result if defined?(@result)

    @result = calculate_resources
  end

  def next_page
    anchor_value =
      if external_anchor_column?
        public_send_chain_from_sql(self.resources.last, @anchor_column)
      else
        self.resources.last&.public_send(@anchor_column)
      end

    @path_helper.call(
      anchor_column: @anchor_column,
      anchor_value: anchor_value,
      sort_direction: @sort_direction,
      anchor_id: self.resources.last&.id
    )
  end

  private

  def calculate_resources
    resources =
      if can_calculate_nth_page?
        calculate_next_page
      else
        calculate_first_page
      end

    resources
  end

  def comparator_for_fetching_resources
    if @sort_direction == CursorPagination::ASC
      GREATER_THAN_OPERATOR
    elsif @sort_direction == CursorPagination::DESC
      LESS_THAN_OPERATOR
    else
      raise COMPARATOR_INTERNAL_BUG
    end
  end

  def can_calculate_nth_page?
    @anchor_column && @anchor_id
  end

  def calculate_first_page
    apply_sort_direction(@ar_relation)
  end

  def calculate_next_page
    if external_anchor_column?
      table, column = @anchor_column.split(".")

      qualified_anchor_column = "`#{table}`.`#{column}`"
    else
      qualified_anchor_column = "#{@ar_relation.quoted_table_name}.#{@sql_anchor_column}"
    end

    qualified_anchor_pk_column = "#{@ar_relation.quoted_table_name}.#{@ar_relation.quoted_primary_key}"

    where_clause =
      if nulls_listed_first? && !@anchor_value.nil?
        @ar_relation.where("(#{qualified_anchor_column}, #{qualified_anchor_pk_column}) #{comparator_for_fetching_resources} (?, ?)", @anchor_value, @anchor_id)
      elsif nulls_listed_first? && @anchor_value.nil?
        @ar_relation.where("(#{qualified_anchor_column} IS NULL AND #{qualified_anchor_pk_column} #{comparator_for_fetching_resources} ?) OR (#{qualified_anchor_column} IS NOT NULL)", @anchor_id)
      elsif nulls_listed_last? && !@anchor_value.nil?
        @ar_relation.where("(#{qualified_anchor_column} IS NULL) OR ((#{qualified_anchor_column}, #{qualified_anchor_pk_column}) #{comparator_for_fetching_resources} (?, ?))", @anchor_value, @anchor_id)
      elsif nulls_listed_last? && @anchor_value.nil?
        @ar_relation.where("#{qualified_anchor_column} IS NULL AND #{qualified_anchor_pk_column} #{comparator_for_fetching_resources} ?", @anchor_id)
      end

    apply_sort_direction(where_clause)
  end

  def apply_sort_direction(ar_relation)
    ar_relation
      .order("#{@anchor_column} #{@sort_direction}", @ar_relation.primary_key => @sort_direction)
      .limit(PAGE_SIZE)
  end

  def nulls_listed_first?
    # MySQL sorts nulls first for ascending order, and null last for descending order.
    # TODO:
    #   The concept of null ordering should be database agnostic and modifiable.
    #   For example, UX might decide that we need some other type of ordering.
    @sort_direction == CursorPagination::ASC
  end

  def nulls_listed_last?
    !nulls_listed_first?
  end

  def primary_key_selected?(ar_relation)
    ar_relation.select_values.empty? || ar_relation.select_values.include?(@ar_relation.primary_key.to_sym)
  end

  # Gets an ActiveRecord instance's associated attribute via its qualified column sql identifier.
  #
  # Given qualified_column_sql_identifier = "joined_tables.column", it will call `.joined_table.column` on `object`.
  # `object` must be an ActiveRecord instance.
  def public_send_chain_from_sql(object, qualified_column_sql_identifier)
    # We limit `split` to 2 because we are assuming that the SQL identifier is in table.column format.
    association, attribute = qualified_column_sql_identifier.split(".", 2).each_with_index.map do |string, index|
      # The first element should be the joined table's sql identifier.
      # These are always pluralized, so we must singularize it in order to use it as a method call.
      index == 0 ? string.singularize : string
    end

    object.try!(association).try!(attribute)
  end

  # Heuristic to check if the `anchor_column` is a joined column.
  def external_anchor_column?
    @anchor_column.include?(".")
  end

  class Exception
    class InvalidSortDirection < StandardError
    end

    class PrimaryKeyNotSelected < StandardError
    end
  end
end

