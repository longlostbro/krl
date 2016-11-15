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
            wrangler:children();
        };
	}
  
	rule create_vehicle{
    	select when car new_vehicle
    	pre{
            random_name = "Test_Child_" + math:random(999);
            name = event:attr("name").defaultsTo(random_name);
          }
          {
            wrangler:createChild(name);
            send_directive("Item created") with attributes = "#{meta}" and name = "#{name}" and eci = meta:eci() ;
          }
          always{
            log("Item created ");
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
