ruleset hello_world {
  meta {
    name "track_trips"
    description <<
track_trips
>>
    author "David Taylor"
    logging on
 
  }
  global {
 
  }
  rule process_trip {
    select when car new_trip
	pre{
		m = event:attr("mileage")
	}
    send_directive("trip") with
      length = m;
  }
 
}