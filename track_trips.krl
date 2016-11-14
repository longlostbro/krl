ruleset hello_world {
	meta {
		name "track_trips"
		description <<
			track_trips
		>>
		author "David Taylor"
		logging on
		sharing on
		provides long_trip
	}
	global {
		long_trip = 500;
	}
	rule process_trip {
		select when car new_trip
		pre{
			m = event:attr("mileage");
			trip_processed = { 
				"mileage" : m 
			};
		}
		if not m.isnull() then {
			send_directive("say") with
				length = m;
		}
		fired {
			raise explicit event 'trip_processed' 
				attributes trip_processed;
			log "Raising event explicit:trip_processed with"+trip_processed;
		}
	}
	rule find_long_trips {
		select when explicit trip_processed
		pre{
			m = event:attr("mileage");
			find_long_trips = {
				"mileage" : m,
				"test" : m
			};
		}
		klog("event explicit:trip_processed raised");
		if m > long_trip then {
			send_directive("say") with
				status = "Found long trip!";
		}
		fired{
			log "Long trip found. Raising event explicit:found_long_trip";
			raise explicit event 'found_long_trip' 
				attributes find_long_trips;
		}
		else {
			log "No long trip found";
		}
	}
}
