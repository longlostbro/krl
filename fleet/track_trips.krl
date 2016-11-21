ruleset track_trips {
	meta {
		name "track_trips"
		description <<
			trip_store
		>>
		author "David Taylor"
		logging on
		provides trips, long_trips, short_trips, subs
		sharing on
	}
	global {
  subs = function()
  {
    subs = wrangler:subscriptions(null,"status",null);
    subs{"subscriptions"}
  };
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
			m = event:attr("mileage").klog("mileage:");
			init =	{};
			id = random:uuid().klog("randomID:");
			t = time:now().klog("time:");
			trip =	
			{
				"mileage": m,
				"timestamp": t
			}.klog("Trip:");
			message = 
			{
				"id": id,
				"mileage": m,
				"timestamp": t
			}.klog("message:");
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

	rule send_report {
		select when explicit report_requested
		pre {
			entname = wrangler:name().klog("entname:");
			my_name = entname{"picoName"}.klog("my name is :");
			fleet_cid = event:attr("fleet_cid").klog("fleet_cid");
			trips = trips().decode().klog("trips:");
		}
		{
			event:send({"cid":fleet_cid}, "explicit", "report_returned")
            with attrs = {
              "trips":trips,
              "name":my_name
            }.klog("sending with:") 
            and cid_key = fleet_cid
		}
		always {
			log "trips cleared";
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
	rule autoAccept {
	  select when wrangler inbound_pending_subscription_added
	  pre{
	    attributes = event:attrs().klog("subcription :");
	    }
	    {
			send_directive("inbound_pending_subscription_added") with
				attrs = event:attrs();
	    }
	  always{
	    raise wrangler event 'pending_subscription_approval'
	        attributes attributes;       
	        log("auto accepted subcription.");
	  }
	}
}