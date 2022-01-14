/**
* Name: Task1
* Based on the internal empty template. 
* Author: zainab
* Tags: 
*/


model Task1

global {
    int N <- 4; 
    
    init {
        create Queen number: N;
        
    }
    list<Queen> queens;
    list<Chessboardsquare> Chessboardsquares;
    
}

grid Chessboardsquare skills:[fipa] width:N height:N{
   
   bool busy <- false;
   init {
   		color <-((grid_x + grid_y) mod 2 = 1)?  #black :  #white;		
		Chessboardsquares << self;
   }
 
}

species Queen skills:[fipa] {
    int myIndex;
    int currentRow <- 0;
    Chessboardsquare currentPosition <-  nil;
    bool noPositionFound <- false; 	// used to inform previous queen to reposition
    bool foundPosition <- false; //used to inform next queen of her turn
    bool searchPosition <- false; // used to sarch a new position
    
    init {
    	queens << self;
    	location <- {-10, 0};
    	myIndex <- length(queens) - 1;
    	if (length(queens) = N) {
    		do start_conversation with:(to: [queens[0]], protocol: 'fipa-request', performative: 'inform', contents: ['FindPosition']);        
        	write "Let's get started!!!!";
    	}
    }
    
    reflex receiveMessages when: !empty(informs) {
    	message msg <- informs[0];
    	if(container(msg.contents)[0] = 'FindPosition') {
    		searchPosition <- true;
    		write name + ": Searching a new position";
    	} else if (container(msg.contents)[0] = 'RePosition') {
    		// free your old position
    		currentRow <- (currentRow + 1) mod N;
    		foundPosition <- false;
    		currentPosition.busy <- false;
    		currentPosition <- nil; 
    		location <- {-10, 0};
    		
    		if (currentRow = 0) {
    			noPositionFound <- true;
    		} else {
    			searchPosition <- true;
    		}
    	}
        informs <- nil;
    }
    
    // tell previous queen to reposition
	reflex informPredecessor when: noPositionFound {
		Queen predecessor <- queens[myIndex - 1];
        do start_conversation with:(to: [predecessor], protocol: 'fipa-request', performative: 'inform', contents: ['RePosition']);
        write name + ": is asking " + predecessor + "to move";
        noPositionFound <- false;
	}
     
    
	reflex informSuccessor when: foundPosition {
         if(myIndex != N -1) {
         	Queen successor <- queens[myIndex +1];
             write name + ": Found a position: " + currentPosition;
             do start_conversation with:(to: [successor], protocol: 'fipa-request', performative: 'inform', contents: ['FindPosition']);
         } else {
             write "All queens found their positions!";
         }
         foundPosition <- false;
        
    }
    
   
     
    reflex searchPosition when: searchPosition{
      	bool safePlace;
      	searchPosition <- false;
        loop i from: currentRow to: N - 1 {   
        	
        	safePlace <- checkRowAndDiagonal(i,myIndex);
        	if(safePlace) {
   
        		currentRow <- i;
        		currentPosition <- Chessboardsquares[(N * i) + myIndex];
        		location <- currentPosition.location;
        		currentPosition.busy <- true;
        		foundPosition <- true;
        		break;
        	}
        	
        	if(i = (N-1) and !foundPosition) {
        		noPositionFound <- true;
        		currentRow <- 0;
        		foundPosition <- false;
        		location <- (point(-10,0));
        		break;
        	}
        	
        	
        } 
        
     }
  	
  	//true if row and diagonal are not under attack
	bool checkRowAndDiagonal(int row, int col) {
		
		//check if row is  busy
     	int c <- myIndex -1;
 		loop while: c >= 0 {
    		Chessboardsquare square <- Chessboardsquares[(N * row) + c];
    		if(square.busy = true) {
    			return false;
    		}
    		c <- c -1;
   		}
   		
   		// check if top-left is busy
   		int x <- col - 1;
    	int y <- row - 1;
    	loop while: (y >= 0 and x >= 0) {
    		Chessboardsquare square <- Chessboardsquares[(N * y) + x];
    		if(square.busy = true) {
        		return false;
        	}
        	y <- y - 1;
     		x <- x - 1;
    	}
    	
    	//check if bottom-left is busy
    	x <- col + 1;
    	y <- row - 1;
    	loop while: (y < N and y >= 0 and x >= 0) {
    		Chessboardsquare square <- Chessboardsquares[(N * y) + x];
    		if(square.busy = true) {
        		return false;
        	}
        	y <- y + 1;
     		x <- x - 1;
    	}
    	return true;
   		
    }
  
     
    aspect default {
    	file f <-image_file("chess-queen.png");
        draw f size:(8) at: location;
    }
}

experiment main type: gui {
   
    output {
        display map type: java2D {
            grid Chessboardsquare lines: #black ;
            species Queen;
        }
    }
}

