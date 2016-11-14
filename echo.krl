ruleset hello_world {
  meta {
    name "Echo"
    description <<
My first ruleset
>>
    author "David Taylor"
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
  rule hello {
    select when echo hello
    send_directive("say") with
      something = "Hello World";
  }
  rule message {
    select when echo message
	pre{
		m = event:attr("input")
	}
    send_directive("say") with
      something = m;
  }
 
}
