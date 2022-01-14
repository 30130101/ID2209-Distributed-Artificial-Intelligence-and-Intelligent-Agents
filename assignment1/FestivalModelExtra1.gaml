/**
* Name: FestivalModelExtra1
* Based on the internal empty template. 
* Author: Zainab Alsaadi & Arthur Simonsson
* Tags: 
*/

	

model FestivalModelExtra1

/* Insert your model definition here */
global{
	
	int number_of_guests <- 5;
	int number_of_stores <- 5;
	int number_of_infoCenters <- 1;
	
	init{
		create guests number: number_of_guests;
		create stores number: number_of_stores;
		create info_center number: number_of_infoCenters;
	}
}

species guests skills:[moving]{
	
	init{
		location <- self.location;
	}
	
	int distance_traveled <- 0;
	// lists for remembering stores
	list<stores> restaurants <- nil;
	list<stores> bars <- nil;
	
	bool got_help <-false;
	bool hungry <- false;
	bool thirsty <- false;
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
				
				//decide if you want to revisit old place
				//or to go to info center
				
				if (hungry and!empty(restaurants) and flip(0.6)){
					stores restaurant <- one_of(restaurants);
					self.targetPoint <- restaurant.location;
					self.got_help <- true;
					//write("rests: "+ restaurants);
				}else if(thirsty and!empty(bars)and flip(0.6)){
					stores bar <- one_of(bars);
					self.targetPoint <- bar.location;
					self.got_help <- true;
					//write("bars: "+ bars);
				}else{
					ask info_center {
						myself.targetPoint <- self.location;
					}
				}

			}

		} 
	}
	reflex print_traveled_distance when: cycle=1000{
		write("travelled distance: "+ distance_traveled);
	}
	 
	reflex moveToTarget when: targetPoint != nil{
		do goto target: targetPoint;
		distance_traveled <- distance_traveled+length(goto);
		
	}
	
	reflex enterStore when: got_help and location distance_to targetPoint=0{
		
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
					//add restaurant  to agent memory
					self.restaurants << restaurant;
					self.got_help <- true;
			} else if (self.thirsty){
					stores juice_bar <- one_of(myself.bars);
					self.targetPoint <- juice_bar.location;
					//add bar to agent memory
					self.bars << juice_bar;
					self.got_help <- true;
			}
		}
	}
}

experiment xp type: gui{
	
	output{
		display ds{
			species guests aspect: info;
			species stores aspect: base;
			species info_center aspect: base;
		}
	}
}


