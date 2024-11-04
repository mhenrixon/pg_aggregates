# PgAggregates

PgAggregates provides Rails integration for managing PostgreSQL aggregate functions. It allows you to version your aggregate functions and handle them through migrations, similar to how you manage database schema changes.

## Features

- Versioned aggregate functions
- Rails generator for creating new aggregates
- Migration support for adding/removing aggregates
- Proper schema.rb dumping
- Support for multiple PostgreSQL versions

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'pg_aggregates'
```

And then execute:

```bash
$ bundle install
```

## Usage

### Creating a New Aggregate

Generate a new aggregate function:

```bash
$ rails generate pg:aggregate sum_squares
```

This will create:
- A SQL file in `db/aggregates/sum_squares_v1.sql`
- A migration file to create the aggregate

You can specify a version:

```bash
$ rails generate pg:aggregate array_sum --version 2
```

### SQL Definition

Edit the generated SQL file (`db/aggregates/sum_squares_v1.sql`):

```sql
CREATE AGGREGATE sum_squares(numeric) (
  sfunc = numeric_add,
  stype = numeric,
  initcond = '0'
);
```

### Migrations

The generated migration will look like:

```ruby
class CreateAggregateSumSquares < ActiveRecord::Migration[7.0]
  def change
    create_aggregate "sum_squares", version: 1
  end
end
```

You can also create aggregates inline:

```ruby
class CreateAggregateArraySum < ActiveRecord::Migration[7.0]
  def change
    create_aggregate "array_sum", sql_definition: <<-SQL
      CREATE AGGREGATE array_sum(numeric[]) (
        sfunc = array_append,
        stype = numeric[],
        initcond = '{}'
      );
    SQL
  end
end
```

### Managing Versions

When you need to update an aggregate, create a new version:

1. Generate a new version:
```bash
$ rails generate pg:aggregate sum_squares --version 2
```

2. Update the SQL in `db/aggregates/sum_squares_v2.sql`

3. Create a migration to update to the new version:
```ruby
class UpdateAggregateSumSquares < ActiveRecord::Migration[7.0]
  def change
    drop_aggregate "sum_squares", "numeric"
    create_aggregate "sum_squares", version: 2
  end
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/mhenrixon/pg_aggregates. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/mhenrixon/pg_aggregates/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the PgAggregates project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/mhenrixon/pg_aggregates/blob/main/CODE_OF_CONDUCT.md).