
// varibles 
// ent:my_picos
// ent:picos_attributes


// operators are camel case, variables are snake case.


// questions
// standard state change function??
// when should we use klogs? what is the standard? varible getters|| mutators 
// is log our choice of status setting for rules ? when should we send directives. can we send directives in postlude with status varible?
// varible validating for removing , deleteing, uninstalling
// when registering a ruleset if you pass empty peramiters what happens

//old channel create uses a "login" eci to create a new channel, why and should we do it that way? 

//whats the benifit of forking a ruleset vs creating a new one?
//pci: lacks abillity to change channel type 

ruleset b507199x5 {
  meta {
    name "nano_manager"
    description <<
      Nano Manager ( ) Module

      use module  b507199x5 alias nano_manager

      This Ruleset/Module provides a developer interface to the PICO (persistent computer object).
      When a PICO is created or authenticated this ruleset
      will be installed into the Personal Cloud to provide an Event layer.
    >>
    author "BYUPICOLab"
    
    logging off

    use module b16x24 alias system_credentials
    // errors raised to.... unknown

    // Accounting keys
      //none
    provides installedRulesets, describeRulesets, //ruleset
    channels, channelAttributes, channelPolicy, channelType, //channel
    children, parent, attributes, //pico
    subscriptions, channel, eciFromName, subscriptionsAttributes, //subscription
    currentSession,standardError
    sharing on

  }

  //dispatch {
    //domain "ktest.heroku.com"
  //}
  global {
    //functions
	
	
  //-------------------- Rulesets --------------------
    installedRulesets = function() {
      eci = meta:eci().klog("eci: ");
      results = pci:list_ruleset(eci).klog("results of pci list_ruleset");//defaultsTo("error",standardError("pci list_ruleset failed"));  
      rids = results{'rids'}.defaultsTo("error",standardError("no hash key rids"));
      {
       'status'   : (rids neq "error"),
        'rids'     : rids
      };
    }
    describeRulesets = function(rids) {//takes an array of rids as parameter // can we write this better???????
      //check if its an array vs string, to make this more robust.
      rids_string = ( rids.typeof() eq "array" ) => rids.join(";") | ( rids.typeof() eq "str" ) => rids | "" ;
      describe_url = "https://#{meta:host()}/ruleset/describe/#{$rids_string}";
      resp = http:get(describe_url);
      results = resp{"content"}.decode().defaultsTo("",standardError("content failed to return"));
      {
       'status'   : (resp{"status_code"} eq "200"),
       'description'     : results
      };
    }
 /*  installedRulesetsDiscription = function(){ // for develpers ??
      rulesets = installedRulesets();
      rids = rulesets{"rids"};
      description = describeRulesets(rids);
      {
       'status'   : (description{'status'}),
       'descriptions'     : description{'description'}
      };
    }*/
    installRulesets = defaction(eci, rids){
      new_ruleset = pci:new_ruleset(eci, rids);
      send_directive("installed #{rids}");
    }
    uninstallRulesets = defaction(eci, rids){
      deleted = pci:delete_ruleset(eci, rids);
      send_directive("uninstalled #{rids}");
    }
  //-------------------- Channels --------------------
    channels = function() { 
      eci = meta:eci();
      results = pci:list_eci(eci).defaultsTo({},standardError("undefined")); // list of ECIs assigned to userid
      channels = results{'channels'}.defaultsTo("error",standardError("undefined")); // list of channels if list_eci request was valid
      {
        'status'   : (channels neq "error"),
        'channels' : channels
      };
    }
    channelAttributes = function(eci) {
      results = pci:get_eci_attributes(eci).defaultsTo("error",standardError("undefined")); // list of ECIs assigned to userid
      {
        'status'   : (results neq "error"),
        'Attributes' : results
      };
    }
    channelPolicy = function(eci) {
      results = pci:get_eci_policy(eci).defaultsTo("error",standardError("undefined")); // list of ECIs assigned to userid
      {
        'status'   : (results neq "error"),
        'Policy' : results
      };
    }
    channelType = function(eci) { // put this as an issue in kre engine for pci function. old accounts may have different structure as there types, "type : types"
      my_channels = channels().defaultsTo("error",">> undefined >>");

      getType = function(eci,my_channels) { // change varible names
        channels = channels{"channels"}.defaultsTo("undefined",standardError("undefined"));
        channel = channels.filter( function(channel){channel{"cid"} eq eci } ).defaultsTo( "error",standardError("undefined"));
        chan = channel[0];
        type = chan{"type"};
        temp = (type.typeof() eq "str" ) => type | type.typeof() eq "array" => type[0] |  type.keys();
        type2 = (temp.typeof() eq "array") => temp[0] | temp;   
        type2;
      };
      type = ((my_channels{"status"}) && (channels neq {} )) => getType() | "error";
      {
        'status'   : (type neq "error"),
        'channels' : channels
      };
    }
    updateAttributes = defaction(eci, attributes){
      set_eci = pci:set_eci_attributes(eci, attributes);
      send_directive("updated channel attributes for #{eci}");
    }
    updatePolicy = defaction(eci, policy){
      set_polcy = pci:set_eci_policy(eci, policy); // policy needs to be a map, do we need to cast types?
      send_directive("updated channel policy for #{eci}");
    }
    deleteChannel = defaction(eci) {
      deleteeci =pci:delete_eci(eci);
      send_directive("deleted channel #{eci}");
    }
    createChannel = defaction(eci, options){
      new_eci = pci:new_eci(eci, options);
      send_directive("created channel #{new_eci}");
    }

  //-------------------- Picos --------------------
  currentSession = function() {
    //pci:session_token(meta:eci()).defaultsTo("", standardError("pci session_token failed")); // this is old way.. why not just eci??
    meta:eci();
  };

	children = function() {
		self = meta:eci();
		children = pci:list_children(self).defaultsTo("error", standardError("pci children list failed"));
		{
			'status' : (children neq "error"),
			'children' : children
		}
	}
	parent = function() {
		self = meta:eci();
		parent = pci:list_parent(self).defaultsTo("error", standardError("pci parent retrival failed"));
		{
			'status' : (parent neq "error"),
			'parent' : parent
		}
	}
	attributes = function() {
		{
			'status' : true,
			'attributes' : ent:attributes.put( {'picoName' : ent:name} )
		}
	}
	
	
	prototypes = {
		"core": [
			"a169x625"
		]
	};
	picoFactory = function(myEci, protos) {
		newPicoInfo = pci:new_cloud(myEci);
		newPico = newPicoInfo{"cid"};
		a = pci:new_ruleset(newPico, prototypes{"core"});
		b = protos.map(function(x) {pci:new_ruleset(newPico, prototypes{x});});
		newPico;
	}

  //-------------------- Subscriptions ----------------------
    subscriptions = function() { // slow, whats a better way to prevent channel call, bigO(n^2)
      // list of subs
      subscriptions = ent:subscriptions.defaultsTo("error",standardError("undefined"));
      // list of channels
      channils = channels();
      chans = channils{'channels'};
      // filter list channels to only have subs
      // 2nbigO(n^2) but is faster because of less server calls to database
      filtered_channels = chans.filter( function(channel){
        //channel{'name'} in other array? 
        subscriptions.any( function(name){ 
          (name eq channel{'name'});  
        }); 
      }); 
      // reconstruct list, to be channelname hashed to attributes.
      subs = filtered_channels.map( function(channel){
          {channel{'name'}:channel{'attributes'}};
      });
      /* 
      {"18:floppy" :
          {"status":"pending_incoming","relationship":"","name_space":"18",..}
      */
      status = function(sub){ // takes a subscription and returns its status.
        value = sub.values(); // array of values [attributes]
        attributes = value.head(); // get attributes
        status = (attributes.typeof() eq 'hash')=> // for robustness check type.
        attributes{'status'} |
          'error';
        (status);
      };
      // return a collection of subs based on status.
      subscription = subs.collect(function(sub){
        (status(sub));
      });

      {
        'status' : (subscriptions neq "error"),
        'subscriptions'  : subscription
      };

    }

    randomName = function(namespace){
        n = 5;
        array = (0).range(n).map(function(n){
          (random:word());
          });
        names= array.collect(function(name){
          (checkName( namespace +':'+ name )) => "unique" | "taken";
        });
        name = names{"unique"} || [];

        unique_name =  name.head().defaultsTo("",standardError("unique name failed"));
        (namespace +':'+ unique_name);
    }
    checkName = function(name){
          chan = channels();
          //channels = channels(); worse bug ever!!!!!!!!!!!!!!!!!!!!!!!!!!!
          // in our meetings we said to check name_space, how is that done?
          /*{
          "last_active": 1426286486,
          "name": "Oauth Developer ECI",
          "type": "OAUTH",
          "cid": "158E6E0C-C9D2-11E4-A556-4DDC87B7806A",
          "attributes": null}
          */
          chs = chan{"channels"}.defaultsTo("no Channel",standardOut("no channel found"));
          names = chs.none(function(channel){channel{"name"} eq name});
          (names);

    }
    subscriptionsAttributes = function (value){
      eci = (value.match(re/((([A-Z]|\d)*-)+([A-Z]|\d)*)/)) => 
              value |
              eciFromName(value);

      attributes = channelAttributes(eci);
      attributes{'Attributes'};
    } 

     channel = function (value){
      // if value has a ":"" then attribute is name otherwise its cid 
      // if value is a number with ((([A-Z]|\d)*-)+([A-Z]|\d)*) attribute is cid.
      my_channels = channels();
      attribute = (value.match(re/((([A-Z]|\d)*-)+([A-Z]|\d)*)/)) => 
              'cid' |
              'name';
      chs = my_channels{"channels"}.defaultsTo("no Channel",standardOut("no channel found, by channels"));
      filtered_channels = chs.filter(function(channel){
        (channel{attribute} eq value);}); 
      result = filtered_channels.head().defaultsTo("",standardError("no channel found, by .head()"));
      (result);
    }

      nameFromEci = function(eci){ 
        //eci = meta:eci();
        channil = channel(eci);
        channil{'name'};
      } 

      eciFromName = function(name){
        channil = channel(name);
        channil{'cid'};
      }
    /*findVehicleByBackchannel = function (bc) {
       garbage = bc.klog(">>>> back channel <<<<<");
       vehicle_ecis = nano_manager:subscriptionList(common:namespace(),"Vehicle");
        vehicle_ecis_by_backchannel = vehicle_ecis
                                        .collect(function(x){x{"backChannel"}})
                                     .map(function(k,v){v.head()})
                                        ;
    vehicle_ecis_by_backchannel{bc} || {}
     };*/
  //-------------------- error handling ----------------------
    standardOut = function(message) {
      msg = ">> " + message + " results: >>";
      msg
    }

    standardError = function(message) {
      error = ">> error: " + message + " >>";
      error
    }
  }
  // string or array return array 
  // string or array return string


  //------------------------------------------------------------------------------------Rules
  //-------------------- Rulesets --------------------
  
  rule installRuleset {// should this handle multiple rulesets or a single one
    select when nano_manager install_rulesets_requested
    pre {
      eci = meta:eci().defaultsTo({},standardError("undefined"));
      rids = event:attr("rids").defaultsTo("", ">>  >> ").klog(">> rids attribute <<");
      rid_list = rids.typeof() eq "array" => rids | rids.split(re/;/); 
    }
    if(rids neq "") then { // should we be valid checking?
      installRulesets(eci, rid_list);
    }
    fired {
      log (standardOut("success installed rids #{rids}"));
      log(">> successfully  >>");
          } 
    else {
      log(">> could not install rids #{rids} >>");
    }
  }
  rule uninstallRuleset { // should this handle multiple uninstalls ??? 
    select when nano_manager uninstall_rulesets_requested
    pre {
      eci = meta:eci().defaultsTo({},standardError("undefined"));
      rids = event:attr("rids").defaultsTo("", ">>  >> ").klog(">> rids attribute <<");
      rid_list = rids.typeof() eq "array" => rids | rids.split(re/;/); 
    }
    { 
      uninstallRulesets(eci,rid_list);
    }
    fired {
      log (standardOut("success uninstalled rids #{rids}"));
      log(">> successfully  >>");
          } 
    else {
      log(">> could not uninstall rids #{rids} >>");
    }
  }
 
 //-------------------- Channels --------------------

  rule updateChannelAttributes {
    select when nano_manager update_channel_attributes_requested
    pre {
      eci = event:attr("eci").defaultsTo("", standardError("missing event attr channels"));
      attributes = event:attr("attributes").defaultsTo("error", standardError("undefined"));
      attrs = attributes.split(re/;/);
      //attrs = attributes.decode();
      //channels = Channels();
    }
    if(eci neq "" && attributes neq "error") then { // check?? redundant????
      updateAttributes(eci,attributes);
    }
    fired {
      log (standardOut("success updated channel #{eci} attributes"));
      log(">> successfully >>");
    } 
    else {
      log(">> could not update channel #{eci} attributes >>");
    }
  }

  rule updateChannelPolicy {
    select when nano_manager update_channel_policy_requested // channel_policy_update_requested
    pre {
      eci = event:attr("eci").defaultsTo("", standardError("missing event attr channels"));
      policy = event:attr("policy").defaultsTo("error", standardError("undefined"));// policy needs to be a map, do we need to cast types?
      channels = Channels();
    }
    if(channels{"channelID"} neq "" && policy neq "error") then { // check?? redundant?? whats better??
      updatePolicy(eci, policy);
    }
    fired {
      log (standardOut("success updated channel #{eci} policy"));
      log(">> successfully  >>");
    }
    else {
      log(">> could not update channel #{eci} policy >>");
    }

  }
  rule deleteChannel {
    select when nano_manager channel_deletion_requested
    pre {
      eci = event:attr("eci").defaultsTo("", standardError("missing event attr eci"));
    }
    {
      deleteChannel(eci);
    }
    fired {
      log (standardOut("success deleted channel #{eci}"));
      log(">> successfully  >>");
          } else {
      log(">> could not delete channel #{eci} >>");
          }
        }
  rule createChannel {
    select when nano_manager channel_creation_requested
    pre {
      channel_name = event:attr("channel_name").defaultsTo("", standardError("missing event attr channels"));
      //type = event:attr("type").defaultsTo("", standardError("missing event attr type"));
      //attributes = event:attr("attributes").defaultsTo("", standardError("missing event attr attributes"));
      //attrs = attributes.decode();
      user = currentSession();
      //user = pci:session_token(meta:eci()).defaultsTo("", standardError("pci session_token failed")); // this is old way.. why not just eci??
      
      options = {
        'name' : channel_name//,
     //   'eci_type' : type,
      //  'attributes' : attrs//,
        //'policy' : ,
      };
          }
    if(channel_name.match(re/\w[\w\d_-]*/) && user neq "") then {
      createChannel(user, options);
          }
    fired {
      log (standardOut("success created channels #{channel_name}"));
      log(">> successfully  >>");
          } 
    else {
      log(">> could not create channels #{channel_name} >>");
          }
    }
  
  
  //-------------------- Picos ----------------------
	rule createChild {
		select when nano_manager child_creation_requested
		
		pre {
			myEci = meta:eci();
			
			newPico = picoFactory(myEci, []);
		}

		{
			noop();
		}
		
		fired {
			log(standardOut("pico created"));
		}
	}
	
	rule initializeChild {
		select when nano_manager child_created
		
		pre {
			parentInfo = event:attr("parent");
			name = event:attr("name");
			attrs = event:attr("attributes").decode();
		}
		
		{
			noop();
		}
		
		fired {
			set ent:parent parentInfo;
			set ent:children {};
			set ent:name name;
			set ent:attributes attrs;
		}
	}

	rule setPicoAttributes {
		select when nano_manager set_attributes_requested
		pre {
			newAttrs = event:attr("attributes").decode().defaultsTo("", standardError("no attributes passed"));
		}
		if(newAttrs neq "") then
		{
			noop();
		}
		fired {
			set ent:attributes newAttrs;
		}
		else {
			log "no attributes passed to set pico rule";
		}
	}
	
	rule clearPicoAttributes {
		select when nano_manager clear_attributes_requested
		pre {
		}
		{
			noop();
		}
		fired {
			clear ent:attributes;
		}
	}
	
	rule deleteChild {
		select when nano_manager child_deletion_requested
		pre {
			picoDeleted = event:attr("picoName").defaultsTo("", standardError("missing pico name for deletion"));
			eciDeleted = (picoDeleted neq "") => ent:children{picoDeleted} | "none";
		}
		if(picoDeleted neq "" || ent:children{picoDeleted}.isnull()) then
		{
			pci:delete_cloud(eciDeleted);
		}
		notfired {
			log "deletion failed because no child name was specified";
		}
	}

  //-------------------- Subscriptions ----------------------http://developer.kynetx.com/display/docs/Subscriptions+in+the+nano_manager+Service
   // ========================================================================
  // Persistent Variables:
  //
  // ent:subscriptions = [ uniqe_channel_name,uniqe_channel_name2,..]
  //
  //
  //{
  //     backChannel : {
  //      type: 
  //      name: 
  //       
  //       
  //       attrs: {
  //      ""
  //      (Subscription) "name"  : ,
  //      "name_space": ,
  //       "relationship" : ,
  //        "target_channel"/"event_channel" : ,
  //        "status": 
  //       ],
  //      }
  //    }
  //  }
  //
   // ========================================================================
   // creates back_channel and sends event for other pico to create back_channel.

   // inbound 
   // outbound
  rule requestSubscription {// need to change varibles to snake case.
    select when nano_manager subscription_requested
   pre {
      // attributes for back_channel attrs
      name   = event:attr("name").defaultsTo("standard", standardError("channel_name"));
      name_space     = event:attr("name_space").defaultsTo("shared", standardError("name_space"));
      relationship  = event:attr("relationship").defaultsTo("peer-peer", standardError("relationship"));
      target_channel = event:attr("target_channel").defaultsTo("no_target_channel", standardError("target_channel"));
      channel_type      = event:attr("channel_type").defaultsTo("subs", standardError("type"));
      
      // extract roles of the relationship
      roles   = relationship.split(re/\-/);
      my_role  = roles[0];
      your_role = roles[1];
     // // destination for external event
      subscription_map = {
            "cid" : target_channel
      };
      // create unique_name for channel
      unique_name = randomName(name_space);

      // build pending subscription entry

      pending_entry = {
        "subscription_name"  : name,
        "name_space"    : name_space,
        "relationship" : my_role,
        "target_channel"  : target_channel, // this will remain after accepted
        "status" : "pending_outgoing"
      }; 
      //create call back for subscriber     
      options = {
          'name' : unique_name, 
          'eci_type' : channel_type,
          'attributes' : pending_entry
          //'policy' : ,
      };
    }
    if(target_channel neq "no_target_channel") 
    then
    {
      createChannel(meta:eci(),options);

      event:send(subscription_map, "nano_manager", "add_pending_subscription_requested") // send request
        with attrs = {
          "name"  : name,
          "name_space"    : name_space,
          "relationship" : your_role,
          "event_channel"  : eciFromName(unique_name).klog("eci: "), 
          "status" : "pending_incoming",
          "channel_type" : channel_type
        }.klog("event:send() attributes: ");
    }
    fired {
      log (standardOut("success"));
      log(">> successful >>");
      raise nano_manager event add_pending_subscription_requested
        with status = pending_entry{'status'}
        and channel_name = unique_name;
      log(standardOut("failure")) if (unique_name eq "");
    } 
    else {
      log(">> failure >>");
    }
  }
  // creates back channel if needed, then it adds pending subscription to list of subscriptions.
  // can we put all this in a map and pass it as a attr? the rules internal.
  rule addPendingSubscription { // depends on wether or not a channel_name is being passed as an attribute
    select when nano_manager add_pending_subscription_requested
   pre {
        channel_name = event:attr("channel_name").defaultsTo("SUBSCRIPTION", standardError("channel_name")); // never will defaultto
        channel_type = event:attr("channel_type").defaultsTo("SUBSCRIPTION", standardError("type")); // never will defaultto
        status = event:attr("status").defaultsTo("", standardError("status"));
      pending_subcriptions = (status eq "pending_incoming") =>
         {
            "subscription_name"  : event:attr("name").defaultsTo("", standardError("")),
            "name_space"    : event:attr("name_space").defaultsTo("", standardError("name_space")),
            "relationship" : event:attr("relationship").defaultsTo("", standardError("relationship")),
            "event_channel"  : event:attr("event_channel").defaultsTo("", standardError("event_channel")),
            "status"  : event:attr("status").defaultsTo("", standardError("status"))
          }.klog("incoming pending subscription") |
          {};

      unique_name = (status eq "pending_incoming") => 
            randomName(name_space) |
            channel_name;
      // create new list of subscriptions, if its empty start a new one.
      new_subscriptions = (ent:subscriptions.head() eq 0) => //--------------------------------------could erase your list of subscriptions is there a better way?
              [unique_name] |
              ent:subscriptions.append(unique_name.klog("unique_name : ")); 

      options = {
        'name' : unique_name, 
        'eci_type' : channel_type,
        'attributes' : pending_subcriptions
          //'policy' : ,
      };
    }
    if(status eq "pending_incoming") 
    then
    {
      createChannel(meta:eci(),options);
    }
    fired { 
      log(standardOut("successful pending incoming"));
      raise nano_manager event incoming_subscription_pending; // event to nothing
      set ent:subscriptions new_subscriptions; 
      log(standardOut("failure >>")) if (channel_name eq "");
    } 
    else { 
      log (standardOut("success pending outgoing >>"));
      raise nano_manager event outgoing_subscription_pending; // event to nothing
      set ent:subscriptions new_subscriptions;
    }
  }
  rule approvePendingSubscription { // used to notify both picos to add subscription request
    select when nano_manager approve_pending_subscription_requested
    pre{
      channel_name = event:attr("channel_name").defaultsTo( "no_channel_name", standardError("channel_name"));
      back_channel = channel(channel_name);
      back_channel_eci = back_channel{'cid'};
      attributes = back_channel{'attributes'};
      status = attributes{'status'};
      //back_channel_eci = eciFromName(channel_name).klog("back eci: ");
      //event_channel = back_channel{'attributes'}{'event_channel'}; // whats better?
      event_channel = event:attrs("event_channel").defaultsTo( "no event_channel", standardError("no event_channel"));
      subscription_map = {
            "cid" : event_channel
      };
    }
    if (event_channel neq "no event_channel") then
    {
      //event:send(subscription_map, "nano_manager", "remove_pending_subscription"); // event to nothing needs better name
      event:send(subscription_map, "nano_manager", "add_subscription_requested") // pending_subscription_approved..
       with attrs = {"event_channel" : back_channel}
       and status = "pending_outgoing";
    }
    fired 
    {
      log (standardOut("success"));
    //  raise nano_manager event 'remove_pending_subscription' // event to nothing  
    //  with channel_name = channel_name;

      raise nano_manager event 'event add_subscription_requested'
      with channel_name = channel_name
       and status = "pending_incoming";
    } 
    else 
    {
      log(">> failure >>");
    }
  }
  rule addSubscription { // changes attribute status value to subscribed
    select when nano_manager add_subscription_requested
    pre{
      channel_name = event:attrs("channel_name").defaultsTo( "no channel name", standardError("no channel name"));
      event_channel = event:attrs("event_channel").defaultsTo( "no event_channel", standardError("no event_channel"));
      status = event:attr("status").defaultsTo("", standardError("status"));

      outGoing = function(event_channel){
        back_channel_eci = meta:eci(); // channel event came in on.
        attributes = subscriptionsAttributes(back_channel_eci);
        attr = attributes.put(["status"],"subscribed"); // over write original status
        attrs = attr.put(["event_channel"],event_channel); // add event_channel
        attrs;
      };

      incoming = function(channel_name){
        attributes = subscriptionsAttributes(channel_name);
        attr = attributes.put(["status"],"subscribed");
        attr;
      };
      // if no name its outgoing accepted
      // if name its incoming accepted
      attributes = (status eq "pending_outgoing" ) => 
            outGoing(event_channel) | 
            incoming(channel_name);
      
      // get eci to change channel attributes
      eci = (status eq "pending_outgoing" ) => 
            meta:eci() | 
            eciFromName(channel_name);
    }
    // always update attribute changes
    {
     updateAttributes(eci,attributes);
    }
    fired {
      log (standardOut("success"));
     // raise nano_manager event 'subscription_added' // event to nothing
     // with channel_name = channel_name;
      } 
    else {
      log(">> failure >>");
    }
  }
    rule removeSubscription {
    select when nano_manager remove_subscription_requested
    pre{
      channel_name = event:attr("channel_name").defaultsTo( "No channel_name", standardError("channel_name"));
      eci = event:attr("eci").defaultsTo( "no eci", standardError("eci"));
      //??????
      name = (channel_name eq "No channel_name") => nameFromEci(eci) | channel_name;
      eCi = (eci eq "no eci") => eciFromName(name)| eci;
    }
    {
      //clean up channel
      deleteChannel(eCi); 
    }
    always {
      log (standardOut("success, attemped to remove subscription"));
    //  raise nano_manager event subscription_removed // event to nothing
    //    with channel_name = channel_name;
      // clean up
      clear ent:subscriptions{name};
    } 
  } 
  rule cancelSubscription {
    select when nano_manager cancel_subscription__requested
            or  nano_manager reject_incoming_subscription_requested
            or  nano_manager cancel_outgoing_subscription_requested
    pre{
      event_channel = event:attr("event_channel").defaultsTo( "No event_channel", standardError("event_channel"));
      channel_name = event:attr("channel_name").defaultsTo( "No channel_name", standardError("channel_name"));
      subscription_map = {
            "cid" : event_channel
      };
      eci = eciFromName(channel_name);
    }
    if(event_channel neq "No event_channel") then
    {
      event:send(subscription_map, "nano_manager", "remove_subscription_requested")
        with attrs = {
          "eci"  : event_channel
        };

    }
    fired {
      raise nano_manager event remove_subscription_requested 
      with channel_name = channel_name
      and eci = eci; 
      log (standardOut("success"));
          } 
    else {
      log(">> failure >>");
    }
  } 
  rule subscribeReset {// for testing purpose, will not be in production 
      select when nano_manager sub_scrip_tions_reset
      pre{
      }
      {
        noop();
      }
      always{
        clear ent:subscriptions;
      }
    } 
// unsubscribed all, check event from parent 

}