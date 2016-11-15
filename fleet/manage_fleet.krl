ruleset manage_fleet {
	meta {
    	name "Fleet Manager"
    	description <<
		manages a fleet of cars
		>>
    	author "David Taylor"
    	logging on
        sharing on
        provides vehicles
        sharing on
        provides show_children
        use module v1_wrangler alias wrangler
	}
	global {
        vehicles = function()
        {
            subs = wrangler:subscriptions(null, "fleet", "vehicle");
            subs{"subscriptions"}
        };
        show_children = function()
        {
            result = wrangler:children();
            children = result{"children"};
            child = children.filter(function(x){x{"name"} eq "Volvo"});
            child
        };
	}
  
	rule create_vehicle{
    	select when car new_vehicle
    	pre{
            random_name = "Test_Child_" + math:random(999);
            name = event:attr("name").defaultsTo(random_name);
            children = wrangler:children();
            child = children{"children"}.filter(function(x){x{"name"} eq name}).head();
            eci = child{"eci"};
          }
          {
            wrangler:createChild(name);
            send_directive("Item created") with eci = eci;
          }
          always{
            log("Item created with eci "+eci);
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

}
