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
		sharing on
		provides long_trips
		sharing on
		provides short_trips
		sharing on
		provides test
	}
	global {
		long_trip = 250;
		trips = function(){
			trips = ent:trips;
			trips
		};
		long_trips = function(){
			long_trips = ent:long_trips;
			long_trips
		};
		short_trips = function(){
			short_trips = ent:trips.filter(function(k,v){ent:long_trips{k}.isnull()});
			short_trips
		};
	}
	rule collect_trips {
		select when explicit processed_trip
		pre{
			m = event:attr("mileage");
			init =	{};
			id = random:uuid();
			t = time:now();
			trip =	
			{
				"mileage": m,
				"timestamp": t
			};
			message = 
			{
				"id": id,
				"mileage": m,
				"timestamp": t
			}
		}
		if not m.isnull() then {
			send_directive("trip") with
				length = m;
		}
		fired {
			set ent:trips init if not ent:trips;
			set ent:trips{[id]} trip;
			log "Raising event explicit:found_long_trip with"+trip_processed;
			raise explicit event 'found_long_trip' 
				attributes message;
		}
	}
	rule collect_long_trips {
		select when explicit found_long_trip
		pre{
			m = event:attr("mileage");
			t = event:attr("timestamp");
			id = event:attr("id");
			init =	{};
			trip =	
			{
				"mileage": m, 
				"timestamp": t 
			};
		}
		
		if m > long_trip then {
			send_directive("long_trip") with
				status = "Found long trip!";
		}
		fired {
			set ent:long_trips init if not ent:long_trips.klog("initialize long_trips");
			set ent:long_trips{[id]} trip;
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
