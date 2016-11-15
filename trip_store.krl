ruleset trip_store {
	meta {
		name "trip_store"
		description <<
			trip_store
		>>
		author "David Taylor"
		logging on
		sharing on
		provides trips
		provides long_trips
		provides short_trips
	}
	global {
		trips = function(){
			trips = ent:trips;
			trips
		};
		long_trips = function(){
			long_trips = ent:long_trips;
			long_trips
		};
		short_trips = function(){
			long_trips = ent:trips.filter(function(k,v){long_trips[k].isnull()});
			long_trips
		};
	}
	rule collect_trips {
		select when explicit processed_trip
		pre{
			m = event:attr("mileage");
			init =	{
						"_0":
						{
							"mileage": 0,
							"timestamp": time:now()
						}
					}
		}
		if not m.isnull() then {
			send_directive("trip") with
				length = m;
		}
		fired {
			log "trip stored";
			set ent:trips init if not ent:trips["_0"];
			set ent:trips[random:uuid()] { "mileage": m, "timestamp": time:now()};
		}
	}
	rule collect_long_trips {
		select when explicit found_long_trip
		pre{
			m = event:attr("mileage");
			init =	{
						"_0":
						{
							"mileage": 0,
							"timestamp": time:now()
						}
					}
		}
		if not m.isnull() then {
			send_directive("longtrip") with
				length = m;
		}
		fired {
			set ent:long_trips init if not ent:long_trips["_0"].klog("initialize long_trips");
			set ent:long_trips[random:uuid()] { "mileage": m, "timestamp": time:now()}.klog("added long_trip");
		}
	}
	rule clear_trips {
		select when car trip_reset
		always {
			log "trips cleared";
			clear ent:long_trips;
			clear ent:trips;
		}
	}
}
