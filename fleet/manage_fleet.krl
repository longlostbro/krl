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
            subs = wrangler:subscriptions();
            subs{"subscriptions"}
        };
        subs = function() {
          subs = wrangler:subscriptions(null, "name_space", "Closet");
          subs{"subscriptions"}
        }
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
    rule introduce_myself {
      select when pico_systems introduction_requested
      pre {
        sub_attrs = {
          "name": event:attr("name"),
          "name_space": "Closet",
          "my_role": event:attr("my_role"),
          "subscriber_role": event:attr("subscriber_role"),
          "subscriber_eci": event:attr("subscriber_eci")
        };
      }
      if ( not sub_attrs{"name"}.isnull()
        && not sub_attrs{"subscriber_eci"}.isnull()
         ) then
      send_directive("subscription_introduction_sent")
        with options = sub_attrs
      fired {
        raise wrangler event 'subscription' attributes sub_attrs;
        log "subcription introduction made"
      } else {
        log "missing required attributes " + sub_attr.encode()
      }
            
    }

    rule approve_subscription {
        select when pico_systems subscription_approval_requested
        pre {
          pending_sub_name = event:attr("sub_name");
        }
        if ( not pending_sub_name.isnull()
           ) then
           send_directive("subscription_approved")
             with options = {"pending_sub_name" : pending_sub_name
                            }
       fired {
         raise wrangler event 'pending_subscription_approval'
               with channel_name = pending_sub_name;
         log "Approving subscription " + pending_sub_name;
       } else {
         log "No subscription name provided"
       }
    }

    rule remove_subscription {
      select when pico_systems subscription_deletion_requested
      pre {
        pending_sub_name = event:attr("sub_name");
      }
      if ( not pending_sub_name.isnull()
         ) then
           send_directive("subscription_approved")
             with options = {"pending_sub_name" : pending_sub_name }
     fired {
       raise wrangler event 'subscription_cancellation'
             with channel_name = pending_sub_name;
       log "Approving subscription " + pending_sub_name;
     } else {
       log "No subscription name provided"
     }
    }

}
