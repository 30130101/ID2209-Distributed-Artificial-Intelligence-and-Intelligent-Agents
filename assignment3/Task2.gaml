/**
* Name: Task2
* Based on the internal empty template. 
* Author: zainab
* Tags: 
*/


model Task2


global
{
    list<point> stageLocations;
   	list<Stage> stages;
   	
    init {
        create guests number: 8;
        create Stage number: 4;
       
    }
   
}
 
species Stage skills:[fipa]  {
	
	//stage attributes
	list<float> myAttributes <- [];
	rgb color;
	
	init {
		stages << self;
		location <- location;
		stageLocations << location;
		myAttributes <- list_with(6,rnd(10.0));
	}
	/** */
	//chang stage values after some interval
	reflex changeStageValues when:every(20#cycle) {
		myAttributes <- list_with(6,rnd(10.0));
	}
	
	reflex sendValues when: !empty(informs) {
		//send my values to the guests
		loop msg over: informs {
			do inform with:(message: msg, contents: [myAttributes]);
		}
		informs <- [];
	}

    aspect default
    {
        draw square(6) at: location color: #blue;
    }
 
}

 
species guests skills:[moving, fipa] {
    list<float> myPreferences <- [];
    
    point targetStage <- nil;
    bool valuesChanged <- false;
    list<list<float>> stageAttributes <- [];
    list<float> utilityList <- [0.0, 0.0, 0.0, 0.0];

    
    init {
		myPreferences <- list_with(6,rnd(10.0));
		location <-location;
    }
   
   
     reflex recieveValues when: (!empty(informs)) {
     	loop msg over: informs {
            stageAttributes << container(msg.contents)[0];
            
        }
        valuesChanged <- true;
        informs <- [];
     }
     
     
    reflex moveToStage when: targetStage != nil and location distance_to targetStage > 10{
        do goto target:targetStage speed: rnd(10.0);
    }
    
    /** */
    //request stage values 
    reflex getStageAttributes when: every(21#cycle) {
    	stageAttributes <- [];
        do start_conversation with:(to: stages, protocol: 'fipa-request', performative: 'inform', contents: ['Send Values']);
               
     }
     
     reflex calculateUtility when: valuesChanged {
        valuesChanged <- false;
        utilityList <- [0.0, 0.0, 0.0, 0.0];
        //calculate utility in each stage
        loop stageIndex from: 0 to: length(Stage) - 1 {
            loop valueIndex from: 0 to: length(stageAttributes) - 1 {
                list<float> currentStageValues <- stageAttributes[stageIndex];
                utilityList[stageIndex] <- utilityList[stageIndex] + (currentStageValues[valueIndex] * myPreferences[valueIndex]);
            }
            
        }
       
       	// choose max utility
        float maxValue <- max(utilityList);
        write self.name;
        write "Utility List: "+utilityList;
        write "My Max Value: "+maxValue +"\n";
        
        int maxIndex <- 0;       
        loop currentUtilityIndex from:0 to: length(utilityList) - 1 {
        	if(maxValue = utilityList[currentUtilityIndex]) {
        		maxIndex <- currentUtilityIndex;
        	}
        }
        
        targetStage <- stageLocations[maxIndex];
        
     }
     
     
     aspect default {
        draw sphere(2) at: location color: #black;
    }
   
}
 
experiment main type: gui
{
   
    output
    {
        display ds
        {
            species guests;
            species Stage;
        }

    }
}