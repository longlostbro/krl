ruleset new_pico {
	meta {
    	name "New Pico"
    	description <<
		creates a child pico
		>>
    	author "David Taylor"
    	logging on 
	}
	global { 
	}
  
	rule createChildren{
    	select when pico_based create_child
    	pre{
    		attributes = {}
                .put(["Prototype_rids"],"") // semicolon separated rulesets the child needs installed at creation
                .put(["name"],"Assignment1") // name for child
                ;
    	}
    	{
    		event:send({"cid":meta:eci()}, "wrangler", "child_creation")  // wrangler os event.
    		with attrs = attributes.klog("attributes: "); // needs a name attribute for child
    	}
    	always{
    		log("create child for " + child);
    	}
  	}
}
