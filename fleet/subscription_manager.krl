ruleset manage_fleet {
	meta {
    	name "Fleet Manager"
    	description <<
		manages subscriptions
		>>
    	author "David Taylor"
    	logging on
        sharing on
        provides subs
        use module v1_wrangler alias wrangler
	}
	global {
        subs = function() {
          subs = wrangler:subscriptions(null, "name_space", "Closet");
          subs{"subscriptions"}
        }
	}
    rule subscribe {
      select when subscription_manager subscribe
      pre {
        sub_attrs = {
          "name": event:attr("name"),
          "name_space": "name_space",
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
    rule autoAccept {
	  select when wrangler inbound_pending_subscription_added
	  	pre{
	  		name = meta:name();
	    	attributes = {"pending_sub_name" : meta:name() };
	  	}
	    {
	    	noop();
	    }
	  	always{    
	        log("auto accepted subcription."+name.encode());
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
