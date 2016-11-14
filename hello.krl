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
							  sharing on
							  provides users

							  }
							  global {
								hello = function(obj) {
								  msg = "Hello " + obj
								  msg
								};
								users = function(){
									users = ent:name;
									users
								};
								name = function(id){
									all_users = users();
									first = all_users{[id, "name", "first"]}.defaultsTo("HAL", "could not find user. ");
									last = all_users{[id, "name" , "last"]}.defaultsTo("9000", "could not find user. ");
									name = first + " " + last;
									name;
								}
								user_by_name = function(full_name){
								  all_users = users();
								  filtered_users = all_users.filter( function(user_id, val){
									constructed_name = val{["name","first"]} + " " + val{["name","last"]};
									(constructed_name eq full_name);
									});
								  user = filtered_users.head().klog("matching user: "); // default to default user from previous steps. 
								  user
								};
							  }
							rule hello_world {
							  select when echo hello
							  pre{
								name = event:attr("name").defaultsTo("HAL 9000","no name passed.");
								full_name = name.split(re/\s/);
								first_name = full_name[0].klog("first : ");
								last_name = full_name[1].klog("last : "); // note we don't check name format its assumed.
								matching_user = user_by_name(name).klog("user result: "); //has id
								user_id = matching_user.keys().head().klog("id: ");
								new_user = {
										  "id"    : last_name.lc() + "_" + first_name.lc(),
										  "first" : first_name,
										  "last"  : last_name
										};
							  }
							  if(not user_id.isnull() ) then {
								  send_directive("say") with
									something = "Hello #{name}";
							  }
							  fired {
								  log "LOG  says hello to " + name ;
								  set ent:name{[user_id,"visits"]} ent:name{[user_id,"visits"]} + 1;
							  }
							  else {
								  raise explicit event 'new_user' // common bug to not put in ''.
									attributes new_user;       
								 log "LOG asking to create " + name ;
									 
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
							rule new_user {
							  select when explicit new_user
							  pre{
								id = event:attr("id").klog("our pass in Id: ");
								first = event:attr("first").klog("our passed in first: ");
								last = event:attr("last").klog("our passed in last: ");
								new_user = {
									"name":{
									  "first":first,
									  "last":last
									  },
									"visits": 1
									};
							  }
							  {
								send_directive("say") with
									something = "Hello #{first_name} #{last_name}";
								send_directive("new_user") with
									passed_id = id and
									passed_first = first and
									passed_last = last;
							  }
							  always{
								set ent:name{[id]} new_user;
							  }
							}
                          }