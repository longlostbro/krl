ruleset manage_fleet {
	meta {
    	name "Fleet Manager"
    	description <<
		    manages a fleet of cars
		  >>
    	author "David Taylor"
    	logging on
      use module v1_wrangler alias wrangler
      provides vehicles, show_children, subs, childECIbyName, test
      sharing on
	}
	global {
		cloud_url = "https://#{meta:host()}/sky/cloud/";
		cloud = function(eci, mod, func, params) {
		    response = http:get("#{cloud_url}#{mod}/#{func}", (params || {}).put(["_eci"], eci));
		 
		 
		    status = response{"status_code"};
		 
		 
		    error_info = {
		        "error": "sky cloud request was unsuccesful.",
		        "httpStatus": {
		            "code": status,
		            "message": response{"status_line"}
		        }
		    };
		 
		 
		    response_content = response{"content"}.decode();
		    response_error = (response_content.typeof() eq "hash" && response_content{"error"}) => response_content{"error"} | 0;
		    response_error_str = (response_content.typeof() eq "hash" && response_content{"error_str"}) => response_content{"error_str"} | 0;
		    error = error_info.put({"skyCloudError": response_error, "skyCloudErrorMsg": response_error_str, "skyCloudReturnValue": response_content});
		    is_bad_response = (response_content.isnull() || response_content eq "null" || response_error || response_error_str);
		 
		 
		    // if HTTP status was OK & the response was not null and there were no errors...
		    (status eq "200" && not is_bad_response) => response_content | error
		};
    vehicles = function()
    {
        subs = wrangler:subscriptions(null,"subscriber_role","car");
        subs{"subscriptions"}
    };
    subs = function() {
      subs = wrangler:subscriptions(null, "name_space", "name_space");
      subs{"subscriptions"}
    };
    show_children = function ()
    {
      children = wrangler:children();
      children{"children"}
    };
    getSubChannelNameByPicoName = function(name)
    {
        cars = vehicles();
        car_sub_search = cars.filter(function(car){ car.pick("$..subscription_name") eq name });
        car_sub = car_sub_search.head();
        car = car_sub{name};
        channel_name = car{'channel_name'};
        channel_name
    };
    childECIbyName = function (name) {
    	children = show_children();
	    pico = children.filter(function(child){child{"name"} eq name}).head();
	    pico{"eci"}
	  };
	  createChild = defaction(car_name)
    {
    	{
				wrangler:createChild(car_name);
	  		send_directive("new_car") 
	    		with name = car_name;
    	}
    };
	}
	rule generate_reports {
  	select when car report
      foreach vehicles setting(vehicle)
       	pre {
          vehicle_name = "";
       	}
        always {
          log "test"
        }
	}
  rule test {
    select when car test
      send_directive("say") with
        something = "Hello World";
  }
	rule create_vehicle{
  	select when car new_vehicle
  	pre{
      random_name = "Test_Child_" + math:random(999);
      car_name = event:attr("name").defaultsTo(random_name);
    }
    {
    	createChild(car_name);
    }
    always{
      raise car event install_ruleset with rid = "b507938x2.prod" and car_name = car_name;
    }
	}
  rule installRulesetInChild {
    select when car install_ruleset
    pre {
      rid = event:attr("rid");
      pico_name = event:attr("car_name");
    }
    {
    wrangler:installRulesets(rid) with
      name = pico_name;
    }
    always
    {
      raise explicit event subscribe_to_child with name = pico_name;
    }
  }
  rule delete_vehicle{
    select when car unneeded_vehicle
    pre {
        name = event:attr("name");
        channel_name = getSubChannelNameByPicoName(name);
    }
    if(not name.isnull()) then {
        wrangler:deleteChild(name)
    }
    fired {
        log "Deleted child with channel_name " + channel_name;
        raise subscription_manager event subscription_deletion_requested
        	with sub_name = channel_name
    } else {
        log "No child named " + name;
    }
  }
  rule subscribe_to_child {
    select when explicit subscribe_to_child
    pre {
      child_name = event:attr("name");
      child_eci = childECIbyName(child_name);
      sub_attrs = {
        "name": child_name,
        "name_space": 'name_space',
        "my_role": 'fleet',
        "subscriber_role": 'car',
        "subscriber_eci": child_eci
      };
    }
    if ( not sub_attrs{"name"}.isnull()
      && not sub_attrs{"subscriber_eci"}.isnull()
       ) then
    send_directive("subscribe_to_child")
      with options = sub_attrs
    fired {
      raise subscription_manager event 'subscribe' attributes sub_attrs;
      log "subcribing to child" + sub_attr.encode();
    } else {
      log "missing required attributes " + sub_attr.encode();
    }
  }
}