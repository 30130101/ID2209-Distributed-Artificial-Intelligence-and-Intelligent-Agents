/**
* Name: Project
* Based on the internal empty template. 
* Author: zainab
* Tags: 
*/


model Project

global{
	//initial values
	int nb_party_guests <- 10;
	int nb_chill_guests <- 10;
	int nb_moody_guests <- 10;
	int nb_friendly_guests <- 10;
	int nb_trouble_guests <- 10;

	list<point> barLocations <- [{35,35},{35,85}];
	init{
		create party_guests number: nb_party_guests;
		create chill_guests number: nb_chill_guests;
		create moody_guests number: nb_moody_guests;
		create friendly_guests number: nb_friendly_guests;
		create trouble_guests number: nb_trouble_guests;
		create bar number:2;
		create concert number: 1;
		create restaurant number: 1;
	}
}

species common skills:[moving,fipa]{
	bool friendly <- flip(0.3);
	point targetPoint <-nil;
	float energy_consum;
	float min_energy <- 0.0;
	float energy <- 1.0 update: energy - energy_consum min: min_energy;
	
	reflex default when:targetPoint =nil{
		do wander;
	}
	action goto_bar(bar b){
		self.targetPoint <- b.location;
		write self.name + " is going to the bar at"+ self.targetPoint;
	}
	action goto_concert{
		write self.name + " is going to the concert";
		concert c <- one_of(concert);
		self.targetPoint <- c.location;
	}
	
	reflex goto_place when: targetPoint != nil{
		do goto target: targetPoint speed:rnd(0.8,1.3);
	}
		
	//renew targetPoint after a while
	reflex newTargetPoint when: every(rnd(200,300)#cycle){
		targetPoint <-nil;
	}
	
	//target point is restaurant if energy level is lower than 0.30
	reflex goto_restaurant when: energy <= 0.30{
		ask restaurant{
			myself.targetPoint <- self.location;
		}
	}
	
	//die if energy is 0 before making it to the restaurant
	reflex cannot_make_it when: energy <= 0{
		write self.name +" starved to death";
		do die;
	}
	//behavior of guests at restaurant
	reflex at_restaurant when: bool(restaurant at_distance 0){ 
		energy <-1.0;
		targetPoint <-nil;
	}
	
	//guests behavior when they receive friends sequest
	reflex friend_request when: !empty(requests){
		write self.name + " received a friend request from " + (requests at 0).sender;
		if friendly{
			write "accepted";
			do agree with: (message:(requests at 0), 
						contents: [self,"Accepted"]
					);
			
		}else{
			write self.name+" refused being friends";
			do refuse with: (message:(requests at 0), 
						contents: [self,"Refused"]
					);
		}
		requests <- nil;
	}
}

species party_guests parent:common{
	bool generous <-flip(0.9);
	init{
		energy_consum <- rnd(0.003,0.005);
	}
	//chose target location and goto it
	reflex choseTarget when: targetPoint = nil{
		
		if(flip(0.03)){
			bar b <- one_of(bar);
			invoke goto_bar(b);
			b.barHasPartyGuest <- true;

		}else if(flip(0.04)){
			invoke goto_concert;
		}
	}
	
	//if at concert and chill person is there, offer one a drink, if you are generous
	reflex at_concert when: generous and bool(concert at_distance 0.1) and bool(chill_guests at_distance 0.1){

		if(empty(accept_proposals) and empty(reject_proposals)){
			do start_conversation(to::[one_of(chill_guests at_distance 0.1)], protocol::'fipa_contract_net', performative::'propose', contents::["Drink"]);
		}
	}
	
	aspect base{
		draw circle(1.5) color: #blueviolet;
		draw self.name color: #black;
	}
}


species chill_guests parent:common{
	bool annoyed <- false;
	init{
		energy_consum <- rnd(0.001,0.003);
	}
	//chose target location and goto it
	reflex choseTarget when: targetPoint = nil{
		
		if(flip(0.03)){
			bar b <- one_of(bar);
			//go to a bar if it is chill
			if (!b.barHasPartyGuest){
				invoke goto_bar(b);
			}

		}else if(flip(0.04)){
			invoke goto_concert;
		}
	}
	
	// chill person behavior at the bar
	reflex at_bar when: bool(bar at_distance 0.1) and bool(party_guests at_distance 0.1){
		annoyed <- true;
		write self.name+ " is annoyed";
		//leave the bar when annoyed
		self.targetPoint <- nil;
	}
	
	// chill person behavior at the concert when gets offered a drink
	reflex at_concert when: !empty(proposes){
		message s <- proposes at 0;
		write self.name + " received offer " + s.contents + " from "+ s.sender;
		
		//accept the drink if you want it
		if flip(0.5){
					do accept_proposal with: (message:(s), 
						contents: [string(self),"Accept"]
					);
					write self.name +" accepts having a drink";
				}else{
					do reject_proposal with: (message:(s), 
						contents: [string(self),"Reject"]
					);
					write self.name +" rejects having a drink";
				}
		proposes <-nil;
	}
	
	
	aspect base{
		draw circle(1.5) color: #aqua;
		draw self.name color: #black;
	}
}

// the guests with emotional instability
//switch types between chill and party.
species moody_guests parent:common{
	chill_guests cg <- nil;
	party_guests pg <- nil;
	point p <- nil; //to keep location when changing type
	float nrg;//to keep same energy when changing type
	init{
		create chill_guests number:1{myself.cg<-self;}
		nb_chill_guests <- nb_chill_guests+1;
	}
	reflex change_type {
		
		if (!dead(cg) and flip (0.05)){
			write cg.name+"  changes mood";
			ask cg{
				myself.p<-self.location;
				myself.nrg <- self.energy;
				nb_chill_guests <- nb_chill_guests-1;
				do die;
				
			}
			create party_guests number:1{myself.pg<-self;location <-myself.p;energy <- myself.nrg;}
			nb_party_guests <- nb_party_guests+1;
		}
		if(!dead(pg) and flip (0.05)){
 			write pg.name+"  changes mood";
			ask pg{
				myself.p<-self.location;
				myself.nrg <- self.energy;
				nb_party_guests <- nb_party_guests-1;
				do die;
			}
			
			create chill_guests number:1{myself.cg<-self;location <-myself.p;energy <- myself.nrg;}
			nb_chill_guests <- nb_chill_guests+1;
	 	}
		
	}
}


// guests who send friend requests to random people in meeting places. 
species friendly_guests parent:common{
	list<common> friends<-nil; // list of friends of various types.
	list<common> refused<-nil; // list of refused friendships
	
	init{
		energy_consum <- rnd(0.001,0.002);
	}
	
	//chose target location and goto it
	reflex choseTarget when: targetPoint = nil{
		
		if(flip(0.03)){
			bar b <- one_of(bar);
			invoke goto_bar(b);
					
		}else if(flip(0.04)){
			invoke goto_concert;
		}
		
	}
	
	//behavior at a meeting place 
	reflex ask_friend when: (bool(bar at_distance 0.1) or bool(concert at_distance 0.1)) and bool(agents of_generic_species(common) at_distance 0.1) and every(5#cycle){
		//ask if one wants to be your friend if they are not already inb the friends list
		common potentialFriend <- one_of((agents of_generic_species(common)) at_distance 0.1);
		if (!(contains(friends,potentialFriend)) and !(contains(refused,potentialFriend))){
			write "\n";
			write "A friend request is sent from "+ self.name +" to " + potentialFriend;
			do start_conversation(to::[potentialFriend], protocol::'fipa_request', performative::'request', contents::["Friends? :)"]);
		}
	}
	
	reflex add_friend when: !empty(agrees){
		common c <- container((agrees at 0).contents) at 0;
		friends << c;
		//write "friends list: "+friends;
		agrees <-nil;
	}
	
	//if friend request already refused, don't ask again
	reflex refused when: !empty(refuses){
		common c <- container((refuses at 0).contents) at 0;
		refused << c;
		//write "refused list: "+refused;
		refuses<-nil;
	}
	
	aspect base{
		draw circle(1.5) color: #deeppink;
		draw self.name color: #black;
	}
}

//the troublemakers
species trouble_guests parent: common{
	bool make_trouble <-false;
	init{
		energy_consum <- rnd(0.003,0.005);
	}
	
	//chose target location and goto it
	reflex choseTarget when: targetPoint = nil{
		
		if(flip(0.03)){
			bar b <- one_of(bar);
			invoke goto_bar(b);
					
		}else if(flip(0.04)){
			invoke goto_concert;
		}
		
	}
	
	//behavior at concert/bar
	reflex make_trouble when: (bool(bar at_distance 0.1) or bool(concert at_distance 0.1)) and every(8#cycle){
		
		if flip(0.3){
			make_trouble <- true;
		}else{
			make_trouble <- false;
		}
	}
	
	aspect base{
		draw circle(1.5) color: #orange;
		draw self.name color: #black;
	}
}

species places{
	//keep a list of previous trouble makers that are banned from the place
	list<trouble_guests> banned_guests <-nil;
	
		//kick out trouble makers
	reflex kick_out when: !empty(trouble_guests at_distance 0.1){
		list<trouble_guests> tg <- trouble_guests at_distance 0.1;
		loop t over: tg{
			ask (t){
				if (self.make_trouble or (self in myself.banned_guests)){
					self.targetPoint <-nil;
					write self.name +" got kicked out from "+ myself.name color:#red;
					//add it to the banned guests list if its their first visit
					if not(self in myself.banned_guests){
						myself.banned_guests << self;
					}
				}
			}
		}
	}
	
	//remove the ban after a while
	reflex clear_list_of_bans when: every(30#cycle){
		banned_guests <-nil;
	}
	
}

species bar parent: places{
	bool barHasPartyGuest <- false;
	init{
		//assign a location to this bar
		location <- barLocations at 0;
		remove(location) from: barLocations;
	}

	aspect base{
		draw square(5) color: #green;
		draw "bar" color: #black;
	}
}

species concert parent: places{
	init{
		location <- {75,75};
	}
	aspect base{
		draw square(5) color: #red;
		draw "concert" color: #black;
	}
}



species restaurant{
	
	init{
		location <- {15,15};
	}

	
	aspect base{
		draw square(5) color: #lightgreen;
		draw "restaurant" color: #black;
	}
}

experiment xp type: gui{
	output{
		display map type: opengl{
			species chill_guests aspect: base;
			species party_guests aspect: base;
			species friendly_guests aspect: base;
			species trouble_guests aspect: base;
			species bar aspect: base;
			species concert aspect: base;
			species restaurant aspect: base;
		}
		monitor "Number of party_people" value: length(party_guests);
		monitor "Number of chill_peole" value: length(chill_guests);
		monitor "Number of friendly_people" value: length(friendly_guests);
		monitor "Number of trouble_people" value: length(trouble_guests);
		monitor "Total: " value: length(party_guests)+ length(chill_guests)+length(friendly_guests)+length(trouble_guests);
		
		display Population_information refresh: every(5#cycles){
			chart "Species evolution" type: series size: {1,0.5} position: {0, 0} {
				data "Number of party_people" value: length(party_guests) color: #blue;
				data "Number of chill_peole" value: length(chill_guests) color: #red;
				data "Number of friendly_people" value: length(friendly_guests) color: #green;
				data "Number of trouble_peole" value: length(trouble_guests) color: #yellow;
			}
			chart "Chill_people Energy Distribution" type: histogram background: #lightgray size: {0.5,0.25} position: {0, 0.5} {
				data "0.1" value: chill_guests count (each.energy <= 0.10) color:#blue;
				data "0.2" value: chill_guests count ((each.energy > 0.10) and (each.energy <= 0.20)) color:#blue;
				data "0.3" value: chill_guests count ((each.energy > 0.20) and (each.energy <= 0.30)) color:#blue;
				data "0.4" value: chill_guests count ((each.energy > 0.30) and (each.energy <= 0.40)) color:#blue;
				data "0.5" value: chill_guests count ((each.energy > 0.40) and (each.energy <= 0.50)) color:#blue;
				data "0.6" value: chill_guests count ((each.energy > 0.50) and (each.energy <= 0.60)) color:#blue;
				data "0.7" value: chill_guests count ((each.energy > 0.60) and (each.energy <= 0.70)) color:#blue;
				data "0.8" value: chill_guests count ((each.energy > 0.70) and (each.energy <= 0.80)) color:#blue;
				data "0.9" value: chill_guests count ((each.energy > 0.80) and (each.energy <= 0.90)) color:#blue;
				data "1" value: chill_guests count (each.energy > 0.90) color:#blue;
			}
			chart "Party_people Energy Distribution" type: histogram background: #lightgray size: {0.5,0.25} position: {0.5, 0.5} {
				data "0.1" value: party_guests count (each.energy <= 0.10) color:#red;
				data "0.2" value: party_guests count ((each.energy > 0.10) and (each.energy <= 0.20)) color:#red;
				data "0.3" value: party_guests count ((each.energy > 0.20) and (each.energy <= 0.30)) color:#red;
				data "0.4" value: party_guests count ((each.energy > 0.30) and (each.energy <= 0.40)) color:#red;
				data "0.5" value: party_guests count ((each.energy > 0.40) and (each.energy <= 0.50)) color:#red;
				data "0.6" value: party_guests count ((each.energy > 0.50) and (each.energy <= 0.60)) color:#red;
				data "0.7" value: party_guests count ((each.energy > 0.60) and (each.energy <= 0.70)) color:#red;
				data "0.8" value: party_guests count ((each.energy > 0.70) and (each.energy <= 0.80)) color:#red;
				data "0.9" value: party_guests count ((each.energy > 0.80) and (each.energy <= 0.90)) color:#red;
				data "1" value: party_guests count (each.energy > 0.90) color:#red;
			}
			chart "Friendly_people Energy Distribution" type: histogram background: #lightgray size: {0.5,0.25} position: {0.5, 0.75} {
				data "0.1" value: friendly_guests count (each.energy <= 0.10) color:#blue;
				data "0.2" value: friendly_guests count ((each.energy > 0.10) and (each.energy <= 0.20)) color:#green;
				data "0.3" value: friendly_guests count ((each.energy > 0.20) and (each.energy <= 0.30)) color:#green;
				data "0.4" value: friendly_guests count ((each.energy > 0.30) and (each.energy <= 0.40)) color:#green;
				data "0.5" value: friendly_guests count ((each.energy > 0.40) and (each.energy <= 0.50)) color:#green;
				data "0.6" value: friendly_guests count ((each.energy > 0.50) and (each.energy <= 0.60)) color:#green;
				data "0.7" value: friendly_guests count ((each.energy > 0.60) and (each.energy <= 0.70)) color:#green;
				data "0.8" value: friendly_guests count ((each.energy > 0.70) and (each.energy <= 0.80)) color:#green;
				data "0.9" value: friendly_guests count ((each.energy > 0.80) and (each.energy <= 0.90)) color:#green;
				data "1" value: friendly_guests count (each.energy > 0.90) color:#green;
			}
			chart "Trouble_people Energy Distribution" type: histogram background: #lightgray size: {0.5,0.25} position: {0, 0.75} {
				data "0.1" value: trouble_guests count (each.energy <= 0.10) color:#yellow;
				data "0.2" value: trouble_guests count ((each.energy > 0.10) and (each.energy <= 0.20)) color:#yellow;
				data "0.3" value: trouble_guests count ((each.energy > 0.20) and (each.energy <= 0.30)) color:#yellow;
				data "0.4" value: trouble_guests count ((each.energy > 0.30) and (each.energy <= 0.40)) color:#yellow;
				data "0.5" value: trouble_guests count ((each.energy > 0.40) and (each.energy <= 0.50)) color:#yellow;
				data "0.6" value: trouble_guests count ((each.energy > 0.50) and (each.energy <= 0.60)) color:#yellow;
				data "0.7" value: trouble_guests count ((each.energy > 0.60) and (each.energy <= 0.70)) color:#yellow;
				data "0.8" value: trouble_guests count ((each.energy > 0.70) and (each.energy <= 0.80)) color:#yellow;
				data "0.9" value: trouble_guests count ((each.energy > 0.80) and (each.energy <= 0.90)) color:#yellow;
				data "1" value: trouble_guests count (each.energy > 0.90) color:#yellow;
			}
		}
	}
}
