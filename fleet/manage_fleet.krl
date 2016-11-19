ruleset manage_fleet {
	meta {
    	name "Fleet Manager"
    	description <<
		    manages a fleet of cars
		  >>
    	author "David Taylor"
    	logging on
      provides vehicles, show_children, subs, childECIbyName, test
      sharing on
      use module v1_wrangler alias wrangler
	}
	global {
    vehicles = function()
    {
        subs = wrangler:subscriptions();
        subs{"subscriptions"}
    };
    subs = function() {
      subs = wrangler:subscriptions(null, "name_space", "Closet");
      subs{"subscriptions"}
    }
    show_children = function ()
    {
      children = wrangler:children();
      children{"children"}
    }
    childECIbyName = function (name) {
    	children = show_children();
	    pico = children.filter(function(child){child{"name"} eq name}).head();
	    pico{"eci"}
	  };
    test = function () {
    	children = show_children();
	    pico = children.filter(function(child){child{"name"} eq 'test'}).head();
	    pico
	  };
	  createChild = defaction(car_name)
    {
    	{
				wrangler:createChild(car_name);
	  		send_directive("new_car") 
	    		with name = car_name;
    	}
     }
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
      raise car event install_ruleset with rid = "b507938x2.prod" and car_name = name;
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
    }
    if(not name.isnull()) then {
        wrangler:deleteChild(name)
    }
    fired {
        log "Deleted child named " + name;
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