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
        sharing on
        provides subs
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
          children
        }
	}
  
	rule create_vehicle{
    	select when car new_vehicle
    	pre{
            random_name = "Test_Child_" + math:random(999);
            name = event:attr("name").defaultsTo(random_name);
            result = wrangler:children();
            children = result{"children"};
            filterresult = children.filter(function(x){x{"name"} eq name});
            child = filterresult.head();
            eci = child{"eci"};
          }
          {
            wrangler:createChild(name);
            send_directive("Item created") with child = child.encode() and eci = eci.encode();
          }
          always{
            log("Child is: "+child.encode());
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
    rule subscribe {
      select when explicit subscribe_to_child
      pre {
          child_name = event:attr("name");
        sub_attrs = {
          "name": child_name,
          "name_space": 'name_space',
          "my_role": 'fleet',
          "subscriber_role": 'car',
          "subscriber_eci": eci
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
    rule createChild{
    select when subscriptions parent_child_automate
    pre{
      child_name = event:attr("name");
      attr = {}
                              .put(["Prototype_rids"],"b507941x1.prod") // ; separated rulesets the child needs installed at creation
                              .put(["name"],child_name) // name for child_name
                              .put(["parent_eci"],meta:eci()) // eci for child to subscribe
                              ;
    }
    {
      noop();
    }
    always{
      raise wrangler event "child_creation"
      attributes attr.klog("attributes: ");
      log("create child for " + child);
    }
  }
}
