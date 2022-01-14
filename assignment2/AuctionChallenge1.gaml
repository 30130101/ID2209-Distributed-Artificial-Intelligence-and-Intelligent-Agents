/**
* Name: FestivalAuction
* Based on the internal empty template. 
* Author: Zainab
* Tags: 
*/


model FestivalAuction

/* Insert your model definition here */

global{
	
	int number_of_guests <- 5;
	int number_of_stores <- 5;
	int number_of_infoCenters <- 1;
	
	init{
		 
		create guests number: number_of_guests;
		create stores number: number_of_stores;
		create info_center number: number_of_infoCenters;
		create auctioneer number: 1{
			genre <- "clothes";
		}
		create auctioneer number: 1{
			genre <- "art";
		}
	}
}

species auctioneer skills:[fipa]{
	
	list<guests> interested_guests <- nil;
	bool auction_ended <-false;
	string genre;
	int selected_interval <-50;
	int min_value <- 300;
	int start_value;
	list<bool> booleans <-nil;
	
	init{
		location <- self.location;
		start_value <- 500;
	}
	
	reflex map_interested_guests when: !empty(informs){
		loop i over: informs{
			//fill the list of guests
			loop u over:  container(i.contents){
				interested_guests << u;
			}

		} 
		write "All guests interested in "+genre+": "+interested_guests;

		//inform guests of auction starts
		do start_conversation(to::interested_guests, protocol::'fipa_contract_net', performative::'inform', contents::["Auction: "+ genre+" started"]);
	}
 
 	
	reflex send_message when: every(5#cycle) and !auction_ended and !empty(interested_guests){
		write "sending message";
		do start_conversation(to::interested_guests, protocol::'fipa_contract_net', performative::'cfp', contents::[genre+": Selling for: "+start_value]);
		
		if flip(0.2){
			do reduce_price;
		}
	}
	
	//check if you recieved any bids and end auction
	reflex current_bids when: !empty(proposes) and !auction_ended{
		message p <-proposes at 0; //first bidder
		do accept_proposal with:(message: p,  contents: ["Auction Ended"]);
		write genre+": We got a bid from "+ p.contents; 
		write genre+": Auction ended at "+p.contents;
		auction_ended <- true;
	}
	
	//reduce price each while and end auction when min_value is reached.
	action reduce_price{
		start_value <- start_value-selected_interval;
		if (start_value <= min_value){
			auction_ended <- true;
			do start_conversation(to::interested_guests, protocol::'fipa_contract_net', performative::'accept_proposal', contents::["End of auction"]);
			write genre+": Auction ended with no bidders";
		}
	}

	
	aspect base{
		draw circle(1) color: #pink;
		draw string("auctioneer") color: #black;
	}
}


species guests skills:[moving,fipa]{
	
	init{
		location <- self.location;
		clothes <- flip(0.3);
		art <- flip(0.3);

	}
	int distance_traveled <-0;
	bool got_help <-false;
	bool hungry <- false;
	bool thirsty <- false;
	bool clothes <- false;
	bool art <- false;
	int timer <-0;
	point targetPoint <- nil;
	
	//when guest is hungry, target point is info_center	
	reflex beIdle when: targetPoint = nil{
		do wander;
		if every(2#cycle){
			timer <- timer+1;
		}		
		if (timer>rnd(900)){
			self.hungry <-flip(0.2);
			self.thirsty <- flip(0.2);
			if(self.hungry or self.thirsty){
				ask info_center {
					myself.targetPoint <- self.location;
				}
			}
		} 
	}
	
	//let auctioneer know you are interested
	reflex send_info_message when: cycle=0{
		//write string(self)+ clothes +art;
		ask auctioneer{
			if(self.genre="clothes" and myself.clothes){
				do start_conversation(to::[self], protocol::'fipa_contract_net', performative::'inform', contents::[myself]);
			}
			else if(self.genre="art" and myself.art){
				do start_conversation(to::[self], protocol::'fipa_contract_net', performative::'inform', contents::[myself]);
			}
		}
	}
	
	//recieve info about auction
	reflex recieve_info_messag when: !empty(informs) {
		//write informs;
		loop i over: informs{
			write "Information: "+i.contents;
		}
	}
 	
	reflex recieved_message when: !empty(cfps) and every(5#cycle) {

		loop c over: cfps{
			int latest_value <-length(cfps)-1;  //latest price for selling
			message latest <- cfps[latest_value];
			
			write string(self)+" received "+ string(latest.contents);
			
			//buy item?
				if flip(0.05){
					do propose with: (message:(latest), 
						contents: [string(self),string(latest.contents)]
					);
				}
			}
	}	


	//print traveled distance after 1000 cycles, for comparison. 
	reflex print_traveled_distance when: cycle=1000{
		write("travelled distance: "+ distance_traveled);
	}
	 
	reflex moveToTarget when: targetPoint != nil{
		do goto target: targetPoint;
		//calculate the total distance traveled by this agent. 
		distance_traveled <- distance_traveled+length(current_path);
	}
	
	reflex enterStore when: got_help and location distance_to targetPoint=0{

		//agent is now done drinking/eating. Go back to initial state.
		got_help <-false;
	 	hungry <- false;
	 	thirsty <- false;
	 	targetPoint <- nil;
	 	timer <-0;
	}
	
	aspect base{
		draw circle(1) color: #brown;
	}
	
	aspect info {
		draw circle(1) color: #brown;
		
		if(hungry){
			draw string(name+ "hungry") color: #red;
		}else if(thirsty){
			draw string(name+"thirsty") color: #red;
		}else{
			draw string(name) color: #black;
		}
	}
}



species stores{
	init{
		location <- self.location;
		//location <- {70,rnd(70)}; //fixad location along x-axis to faciliate comparison
		bool res <- flip(0.5);
		name <- (res)?"restaurant":"juice bar";
	}
	//can be a juice bar or a restaurant 
	aspect base{
		draw square(4) color: (name ="restaurant")? #purple: #coral;
		draw string(name) color:#black;
	}
}


species info_center{
	
	list<stores> restaurants <- nil;
	list<stores> bars <- nil;
	
	init{
		location <- {50,50};
		ask stores{
			if (self.name = "restaurant"){
				myself.restaurants << self;
			}else{
				myself.bars << self;
			}
		}
	}
	
	aspect base{
		draw square(5) color: #green;
	}

	
	reflex help_guest when: !empty(guests at_distance 0){
		
		ask guests at_distance 0{
			if (self.hungry){
					stores restaurant <- one_of(myself.restaurants);
					self.targetPoint <- restaurant.location;
					self.got_help <- true;
			} else if (self.thirsty){
					stores juice_bar <- one_of(myself.bars);
					self.targetPoint <- juice_bar.location;
					self.got_help <- true;
			}
		}
	}
}

experiment xp type: gui{
	/** 
	output{
		display ds{
			species auctioneer aspect: base;
			species guests aspect: info;
			species stores aspect: base;
			species info_center aspect: base;
		}
	}*/
}
