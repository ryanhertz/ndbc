# NDBC

A ruby gem for getting NDBC (National Data Buoy Center) data.
[http://www.ndbc.noaa.gov/rt_data_access.shtml](http://www.ndbc.noaa.gov/rt_data_access.shtml)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ndbc'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ndbc

## Usage

```
station = NDBC::Station.new(41009)
station.standard_meteorological_data
# output
{
    units: { "YY" => "yr", "MM" => "mo", ... },
    values: [
        {"YY" => "2015", "MM" => "08", ... },
        {"YY" => "2015", "MM" => "08", ... }
    ]
}
```

## Contributing

1. Fork it ( https://github.com/[my-github-username]/ndbc/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
