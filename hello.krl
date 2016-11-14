 ruleset hello_world {
  meta {
    name "Hello World"
    description <<
        A first ruleset for the Quickstart
                          >>
                              author "Phil Windley"
							  logging on
							  sharing on
							  provides hello

							  }
							  global {
								hello = function(obj) {
								  msg = "Hello " + obj
								  msg
								};
							  }
							rule hello_world {
							  select when echo hello
							  pre{
								id = event:attr("id").defaultsTo("_0","no id passed.");
								first = ent:name{[id,"name","first"]};
								last = ent:name{[id,"name","last"]};
							  }
							  {
								send_directive("say") with
								  greeting = "Hello #{first} #{last}";
							  }
							  always {
								  log "LOG says Hello " + first + " " + last ;
							  }
							}
							rule store_name {
							  select when hello name
							  pre{
								id = event:attr("id").klog("our pass in id: ");
								first = event:attr("first").klog("our passed in first: ");
								last = event:attr("last").klog("our passed in last: ");
								init = {"_0":{
											  "name":{
													  "first":"GLaDOS",
													  "last":""}}
										}
							  }
							  {
								send_directive("store_name") with
								passed_id = id and
								passed_first = first and
								passed_last = last;
							  }
							  always{
								set ent:name init if not ent:name{["_0"]}; // initialize if not created. Table in data base must exist for sets of hash path to work.
								set ent:name{[id,"name","first"]}  first;
								set ent:name{[id, "name", "last"]}  last;
							  }
							}
                          }