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
            children
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
    rule create_item {
      select when item new_item
        pre {
        //provided in Kynetx Event  Console as Attributes (or as params of an API call)
        name = event:attr("name");
        owner = event:attr("owner");
        attributes = {}
          .put(["name"], name)
            .put(["owner"], owner)
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

}
