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
		use module  b507199x5 alias wrangler_api
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
	rule parent_eci {
		select when explicit parent_eci
		pre{
			parent_results = wrangler_api:parent();
		}
		{
			send_directive("parent") with
				status = parent_results.encode();
		}
	  always {
		log "parent: "+parent_results;
	  }
	}
	rule childToParent {
	  select when wrangler init_events
	  pre {
	     // find parant
	     // place  "use module  b507199x5 alias wrangler_api" in meta block!!
	     parent_results = wrangler_api:parent();
	     parent = parent_results{'parent'};
	     parent_eci = parent[0]; // eci is the first element in tuple
	     attrs = {}.put(["name"],"Family")
	                    .put(["name_space"],"Tutorial_Subscriptions")
	                    .put(["my_role"],"Child")
	                    .put(["your_role"],"Parent")
	                    .put(["target_eci"],parent_eci.klog("target Eci: "))
	                    .put(["channel_type"],"Pico_Tutorial")
	                    .put(["attrs"],"success")
	                    ;
	  }
	  {
	   noop();
	  }
	  always {
	    raise wrangler event "subscription"
	    attributes attrs;
	    log "testing123";
	  }
	}
}
