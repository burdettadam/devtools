(function($)
{
  var router = new $.mobile.Router( [
    {"#page-authorize": {handler: "pageAuthorize",
         events: "s", // do when we show the page
         argsre: true
       } },


       {"#home": {handler: "home",
		 events: "s", // do when we show the page
		 argsre: true
		} },


    {"#listing": {handler: "listing",
		    events: "s", // do when we show the page
		    argsre: true
     } },
     {"#registering-ruleset": {handler: "registeringRuleset",
				events: "s", // do when we show the page
				argsre: true
      } },
      {"#confirming-deletion": {handler: "confirmingDeletion",
				events: "s", // do when we show the page
				argsre: true
      } },
      {"#updating-url": {handler: "updatingUrl",
			 events: "s", // do when we show the page
			 argsre: true
			} },
      {"#page-picologging": {handler: "picologging",
			     events: "s", // do when we show the page
			     argsre: true
        } }
        ],
        {
          pageAuthorize: function(type, match, ui, page) {
            console.log("manage fuse: authorize page");
            $.mobile.loading("hide");
          }, 
          
          home: function(type, match, ui, page) {
            console.log("home Handler");
            $.mobile.loading("hide");
          },


          listing: function(type, match, ui, page) {
            console.log("listing Handler");

            
              Devtools.getRulesets(function(rids_json){ //the callback/function is where we need to have all of our code
                console.log(rids_json);

              //this is for a table
              /*
              var len = rids_json.length;
              var txt = "";
              if(len > 0){
                for(var i=0;i<len;i++){
                    txt += "<tr><td>"+rids_json[i].rid+"</td><td>"+rids_json[i].uri+"</td><td><a href=\""+rids_json[i].uri+"\" data-role=\"button\" data-icon=\"arrow-r\">button</a></td></tr>";
                      
                  }
                if(txt !== ""){
                        $("#ruleset-list").html(txt);
                        $("#ruleset-list").listview('refresh');
                  }
                else{
                    $("#ruleset-list").html("<tr><td> NONE </td><td> NONE </td>");
                    $("#ruleset-list").listview('refresh');
                }
              } */

              //trying for a list

              console.log("attempting rough listview");

              var keys = rids_json.sort(sortBy("rid_index"));
              console.log("keys: " + keys);
              $.each(rids_json, paint_item);
            //  $.each(keys, paint_item);

            console.log("refreshing manage-list listview.");

            $('#manage-list').listview('refresh');
          });


          // document.getElementById("List-Rulesets").innerHTML = obj;


            /*var frm = "#ruleset-form";
            $(frm)[0].reset();
            var owner_eci = CloudOS.defaultECI; //from pageUpdateProfile

              $("#RID", frm).val(ruleset_obj.rid);
              $("#source-URL", frm).val(ruleset_obj.uri);*/


            },
            registeringRuleset: function(type, match, ui, page) {
              console.log("registering Ruleset Handler");
            },
            confirmingDeletion: function(type, match, ui, page) {
              console.log("confirming Deletion Handler");
            },
            updatingUrl: function(type, match, ui, page) {
              console.log("updating Url Handler");
            },
            picologging: function(type, match, ui, page) {
              console.log("pico logging page");
              $.mobile.loading("hide");
              Pico.logging.status(CloudOS.defaultECI, function(json){
                console.log("Logging status: ", json);
                if(json) {
                  $("#logstatus").val("on").slider("refresh");
                  $("#loglist" ).empty();
                  Pico.logging.getLogs(CloudOS.defaultECI, function(logdata){
                   $.each(logdata, function(i, logobj) {
                     var eid_re = RegExp("\\s+" + logobj.eid);
                     logobj.log_items = logobj.log_items.map(function(i){ return i.replace(eid_re, ''); });
                     $("#loglist" ).append( 
                       snippets.logitem_template(logobj)
                       ).collapsibleset().collapsibleset( "refresh" );
                     $("#loglist").listview("refresh");
                   });
                 });

                } else {
                  $("#logstatus").val("off").slider("refresh");
                }
              });
            } 
          },
          { 
            defaultHandler: function(type, ui, page) {
              console.log("Default handler called due to unknown route (" + type + ", " + ui + ", " + page + ")");
            },
            defaultHandlerEvents: "s",
            defaultArgsRe: true

          });
      // Handlebar templates compiled at load time to create functions
      // templates are included to index.html from Templates directory.
      window['snippets'] = {
        list_rulesets_template: Handlebars.compile($("#list-rulesets-template").html() || ""),
        logitem_template: Handlebars.compile($("#logitem-template").html() || "")
      };

      function plant_authorize_button()
      {
        //Oauth through kynetx
        console.log("plant authorize button");
        var OAuth_kynetx_URL = CloudOS.getOAuthURL();
        $('#authorize-link').attr('href', OAuth_kynetx_URL);
        var OAuth_kynetx_newuser_URL = CloudOS.getOAuthNewAccountURL();
        $('#create-link').attr('href', OAuth_kynetx_newuser_URL);
      }

      function onMobileInit() {
       console.log("mobile init");
       $.mobile.autoInitialize = false;
     }

    function onPageLoad() {// Document.Ready
    	console.log("document ready");
     CloudOS.retrieveSession();
	// only put static stuff here...
	plant_authorize_button();

	$('.logout').off("tap").on("tap", function(event)
  {
	       CloudOS.removeSession(true); // true for hard reset (log out of login server too)
	       $.mobile.changePage('#page-authorize', {
         transition: 'slide'
	       }); // this will go to the authorization page.
       });

	console.log("Choose page to show");

	try {
   var authd = CloudOS.authenticatedSession();
   if(authd) {
    console.log("Authorized");
    document.location.hash = "#home";
  } else {  
    console.log("Asking for authorization");
    document.location.hash = "#page-authorize";
  }
} catch (exception) {

} finally {
 $.mobile.initializePage();
 $.mobile.loading("hide");
}

}

    /////////////////////////////////////////////////////////////////////
    // this is the actual code that runs and sets everything off
    // pull the session out of the cookie.
    $(document).bind("mobileinit", onMobileInit);
    $(document).ready(onPageLoad);
  })(jQuery);

  function sortBy(prop){
    return function(a,b){
      if( a[prop] < b[prop]){
        return 1;
      }else if( a[prop] > b[prop] ){
        return -1;
      }
      return 0;
    };
  }
    function paint_item(id, rids) {//(key,value)

          /*if (typeof vehicle === "undefined") {
        return;
      }*/
          var status = "no status"; // place holder for description
         // console.log("in paint_item");
        //  console.log(id, rids);
          console.log("rid: "+ rids.rid);

        $("#manage-list li:nth-child(1)" ).after( //was #manage-fleet prior
          snippets.list_rulesets_template(
            {"rid": rids["rid"],
            "uri": rids["uri"]
          }));
      }

