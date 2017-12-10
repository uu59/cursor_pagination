# CursorPagination

Value based pagination for `ActiveRecord::Relation` instances.

TODO: remove page size. let the caller limit the relation accordingly
TODO: remove the path helper. expose the cursor instead and let the caller generate the next link
TODO: automate testing setup that requires installing mysql, starting the server, creating the database, etc.
TODO: make gem database agnostic

## Usage

In your controllers:

```ruby
@pagination = CursorPagination.new(
  anchor_column: "name",
  anchor_id: params[:last_id],
  anchor_value: params[:last_value],
  ar_relation: Model.where(params[:filters]),
  sort_direction: CursorPagination::DESC,
  path_helper: lambda do |anchor_column:, anchor_value:, sort_direction:, anchor_id:|
    models_path(
      anchor_column: anchor_column,
      anchor_value: anchor_value,
      sort_direction: sort_direction,
      anchor_id: anchor_id
    )
  end
)
```

In your views:

```ruby
json.models @pagination.resources do |resource|
  json.partial! 'attributes', model: resource
end

json.pagination do
  json.next_page @pagination.next_page
end
```

## API

### `#next_page`

Returns the next page's path.

### `#resources`

Returns the current page's collection.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'cursor_pagination'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install cursor_pagination

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/cursor_pagination.
