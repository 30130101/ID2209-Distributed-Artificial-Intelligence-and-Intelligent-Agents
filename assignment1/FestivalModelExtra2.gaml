/**
* Name: FestivalModel
* Based on the internal empty template. 
* Author: Zainab Alsaadi & Arthur Simonsson
* Tags: 
*/


model FestivalModel

/* Insert your model definition here */

global{
	
	int number_of_guests <- 5;
	int number_of_stores <- 5;
	int number_of_infoCenters <- 1;
	
	init{
		create security_guard number: 1;
		create guests number: 1 {bad<-true;}
		create guests number: number_of_guests;
		create stores number: number_of_stores;
		create info_center number: number_of_infoCenters;
	}
}

species guests skills:[moving]{
	
	init{
		location <- self.location;
	}
	int distance_traveled <-0;
	bool got_help <-false;
	bool hungry <- false;
	bool thirsty <- false;
	bool bad <-false;
	bool killed <-false;
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
	reflex stop when: killed {
		do die;
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
		draw circle(1) color:(bad)?#red:#brown;
		
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
	//report bad guests
	reflex report when: !empty(guests at_distance 0){
		ask guests at_distance 0{
			if (self.bad){
				ask security_guard{
					do follow_guest(myself);
				}
			}
		}
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

species security_guard skills:[moving]{
	init{
		location <- {53,53};
	}
	point my_target <-nil;
	guests bad_guest <- nil;
	action follow_guest(guests badGuest){
		my_target <-badGuest.location;
		bad_guest <-badGuest;
	}
	reflex follow when: my_target !=nil{
		do goto target: bad_guest.location;
	}
	
	reflex kill_guest when: my_target !=nil and location distance_to bad_guest.location=0{
		write(my_target);
		ask bad_guest{
			do die;
		}
		write(name);

		//goto initial state
		my_target <-nil;
		bad_guest <- nil;
		
	}
	reflex go_back when: my_target =nil{
		do goto target: {53,53};
	}

	
	aspect base{
		draw hexagon(2) color:#black ;
	}
}

experiment xp type: gui{
	
	output{
		display ds{
			species security_guard aspect: base;
			species guests aspect: info;
			species stores aspect: base;
			species info_center aspect: base;
		}
		//monitor"Number of Guests" value:number_of_guests;
		//monitor "Number of Stores" value:number_of_stores;
		//monitor"Number of Info Centers" value: number_of_infoCenters;
	}
}

