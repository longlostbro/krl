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
            name = event:attr("name");
            sub_attrs = {
              "name": name+"_subscription",
              "name_space": "vehicles",
              "my_role": "fleet",
              "subscriber_role": "vehicle",
              "subscriber_eci": """"
            };
        }
        if ( not sub_attrs{"name"}.isnull() )
        {
        }
        fired {
            wrangler:createChild(name);
            raise wrangler event 'subscription' attributes sub_attrs;
            log "subcription introduction made"
        }
        else {
            log "missing required attributes " + sub_attr.encode()
        }
        always{
            log("create child names " + name);
        }
  	}
    rule create_item {
      select when item new_item
        pre {
        //provided in Kynetx Event  Console as Attributes (or as params of an API call)
        name = event:attr("name");
        attributes = {}
          .put(["name"], name)
            .put(["Prototype_rids"], "b507940x1.prod"); //Installs rule sets b507780x54.prod and b507780x56.prod in the newly created Pico
        }
        {
        // wrangler api event for child creation. meta:eci() provides the eci of this Pico
            event:send({"cid":meta:eci()}, "wrangler", "child_creation") with attrs = attributes.klog("attributes: ");
      
        //send_directives are sent out via API
        //Output to Kynetx Event Console - Response body
        //or API call - response body
            send_directive("Item created") with attributes = "#{attributes}" and name = "#{name}" ;
        }
        always{
      
        //Not required but does show an example of persistent variable instantiation
        //This entity variable creates a subscription between the child to parent with "name"
        //and the meta:eci() which provides the eci of the current rules set (in this case the parent's eci)
          set ent:subscriptions{"name"} meta:eci();
         
        //this shows up in the pico logs
        log("Create child item for " + child);
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
