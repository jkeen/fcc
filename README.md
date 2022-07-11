# fcc

Query the FCC database for fm, am, and tv information.


This gem uses the new FCC apis and the old FCC apis and combines records to be the most complete version possible. The old (transition.fcc.gov) API provides way more data than the new one does.

## Install

```
gem install fcc
```

## Requirements

* Ruby 2.0.0 or higher

#### Get station information by call sign

```ruby
station = FCC::Station.find(:fm, "KOOP")

if station.exists? && station.licensed?
  #Basic attributes, available quickly because the FCC actually caches these in a CDN: 
  station.id #=> 65320
  station.status #=> LICENSED
  station.rf_channel #=> 219
  station.license_expiration_date #=> "08/01/2021"
  station.facility_type #=> ED
  station.frequency #=> 91.7 
  station.contact #=> <struct FCC::Station::Contact>
  station.owner #=> <struct FCC::Station::Contact>
  station.community #=> <struct FCC::Station::Community city="HORNSBY", state="TX">

  # Extended attributes, takes several seconds to load initially because the FCC is running this endpoint on a 1960s era mainframe operated by trained hamsters. 
  station.station_class #=> A
  station.signal_strength #=> 3.0 kW
  station.antenna_type #=> ND
  station.effective_radiated_power #=> 3.0 kW
  station.haat_horizontal #=> 26.0
  station.haat_vertical #=> 26.0
  station.latitude #=> "30.266861111111112"
  station.longitude #=> "-97.67444444444445"
  station.file_number #=> BLED-19950103KA


  station.to_json #=> 
                [{:band=>"FM",
                :signal_strength=>"3.0 kW",
                :latitude=>"30.266861111111112",
                :longitude=>"-97.67444444444445",
                :station_class=>"A",
                :file_number=>"BLED-19950103KA",
                :effective_radiated_power=>"3.0 kW",
                :haat_horizontal=>"26.0",
                :haat_vertical=>"26.0",
                :antenna_type=>"ND",
                :operating_hours=>nil,
                :licensed_to=>"TEXAS EDUCATIONAL BROADCASTING CO-OPERATIVE, INC.",
                :city=>"HORNSBY",
                :state=>"TX",
                :country=>"US",
                :id=>"65320",
                :call_sign=>"KOOP",
                :status=>"LICENSED",
                :rf_channel=>"219",
                :license_expiration_date=>"08/01/2029",
                :facility_type=>"ED",
                :frequency=>"91.7",
                :contact=>
                 {:name=>"Federico Pacheco",
                  :title=>"",
                  :address=>"3823 Airport Blvd. Suite B",
                  :address2=>"",
                  :city=>"Austin",
                  :state=>"TX",
                  :zip_code=>"78722",
                  :phone=>"(512)472-1369",
                  :fax=>"",
                  :email=>"federico.pacheco@koop.org",
                  :website=>"koop.org"},
                :owner=>{:name=>"TEXAS EDUCATIONAL BROADCASTING CO-OPERATIVE, INC.", :city=>"AUSTIN", :state=>"TX", :phone=>"(512)472-1369"},
                :community=>{:city=>"HORNSBY", :state=>"TX"}}]
  ```
end


### Caching
Extended attributes take several seconds to load from transition.fcc.gov. In order to work around this, we query the entire dataset and then cache the result locally for 3 days (using the lightly gem). To use your own cache, set `FCC.cache=` to your cache class (Rails.cache, maybe?) which should have a #fetch method that should take a key and a block like `cache.fetch(key) { // yield for expensive fetch }}`.  

### Get all station call signs on a particular service (:fm, :am, :tv)

```ruby
results = FCC::Station.index(:fm).results
#=> [{"id"=>"198674", "callSign"=>"KANC", "frequency"=>"99.7", "activeInd"=>"Y"}, {"id"=>"174558", "callSign"=>"WUMZ", "frequency"=>"91.5", "activeInd"=>"Y"}, {"id"=>"184688", "callSign"=>"WHVC", "frequency"=>"102.5", "activeInd"=>"Y"} .... 
```

## Contributing to fcc

* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it
* Fork the project
* Start a feature/bugfix branch
* Commit and push until you are happy with your contribution
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.
