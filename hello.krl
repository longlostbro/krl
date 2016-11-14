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
								  name = event:attr("name").defaultsTo(ent:name,"use stored name");
							  }
							  {
								  send_directive("say") with
									  greeting = "Hello #{name}";
							  }
							  always {
								log ("LOG says Hello " + name);
							  }
							}
							rule store_name {
							  select when hello name
							  pre{
								passed_name = event:attr("name").klog("our passed in Name: ");
							  }
							  {
								send_directive("store_name") with
								  name = passed_name;
							  }
							  always{
								set ent:name passed_name;
							  }
							}
                          }