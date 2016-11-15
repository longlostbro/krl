ruleset manage_fleet {
	meta {
    	name "Fleet Manager"
    	description <<
		manages a fleet of cars
		>>
    	author "David Taylor"
    	logging on
        use module v1_wrangler alias wrangler
        sharing on
        provides vehicles
	}
	global {
        vehicles = function()
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
        }
        always{
            log("create child names " + name);
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
