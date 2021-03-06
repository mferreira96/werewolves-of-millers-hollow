/* Initial beliefs */
alive.

/* Initial goals */
!join_game(game_coordinator).

/* Plan */
+!join_game(Coordinator)
	: .my_name(Me)
	<- .send(Coordinator, tell, role(werewolf, Me)).
	
/*
 * Rules 
 */
 	
all_werewolves_comunicated(Day) :-
	 .count(townsperson_to_eliminate(Day,_,_,_,_), CntVotes) &
	 .count(werewolf(_), CntWerewolves) &
	 .print("Cntvotes = ", CntVotes, " CntWerewolves = ", CntWerewolves) &
	 CntVotes == CntWerewolves.
 	
/*
 * Game setup
 */

/* Add other werewolves to beliefs */
+werewolf(Player)
	: .my_name(Player)
	<- .abolish(werewolf(Player)).

+werewolf(Player)
	<- .print("I've learned that ", Player, " is also a werewolf.").	
	
/* Add townsperson to beliefs */
+player(Player)
	<- 	.random(Random_Number);
		+townsperson(Player, Random_Number);
		.print("I've learned that ", Player, " is playing the game.").
	
/*
 * Game loop
 */
	
/* Wake up during the night*/
+night(Day)
	: .random(N) & N > 0.1
	<- .my_name(Me);
	   .print(Me, " wakes up.");
	   .findall(Probability, townsperson(_, Probability), Probabilities);
	   .max(Probabilities, Prob);
	   .print("My max: ", Prob);
	   .findall([X,Y], townsperson(X,Y), Ys);
	   lib.select_max_or_random(Ys, Name);
	   //?townsperson(Name, Prob);
	   .findall(Werewolf_Name, werewolf(Werewolf_Name), Werewolves);
	   .length(Werewolves, CntWerewolves);
	   .findall(P, townsperson_to_eliminate(Day,_,_,P,-1), Ps);
	   .length(Ps,CntVotes);
	   if (CntWerewolves == 0 | (CntVotes == CntWerewolves))
	   {
	   	 .print(Me, " voted on " , Name);
	   	 .send(game_coordinator, tell, voted_to_eliminate(Day, Me, Name));	
	   }
	   else
	   {
	  	 .send(Werewolves, tell, townsperson_to_eliminate(Day,Me,Name, Prob,0)); 	
	   }.
	   
+night(Day)
 	<- .my_name(Me);
 	   .findall(Name, player(Name), Players);
 	   werewolves_of_millers_hollow.actions.random_player(Players, Player);
	   .send(game_coordinator, tell, voted_to_eliminate(Day, Me, Player));
	   .findall(Werewolf_Name, werewolf(Werewolf_Name), Werewolves);
	   ?townsperson(Player, Prob);
	   .send(Werewolves, tell, townsperson_to_eliminate(Day,Me,Player,Prob,0)).
	   
+townsperson_to_eliminate(Day,From, Player, Pro, Type)
	: all_werewolves_comunicated(Day)	   
	<- .my_name(Me);
	   .findall(Probability, townsperson(_, Probability), Probabilities);
	   .max(Probabilities, Prob); 
	   .findall(P, townsperson_to_eliminate(Day,_,_,P,0), Ps);
	   .length(Ps, CntVotes);
	   if (Prob > Communicated_Probability | CntVotes == 0) 
	   {
	   	?townsperson(Name, Prob);
	   	.print(Me, " Voted on Townsperson_Name = ", Name);
	   	.send(game_coordinator, tell, voted_to_eliminate(Day, Me, Name));	
	   }
	   else
	   {
	   	.max(Ps, Communicated_Probability);
	   	?townsperson_to_eliminate(Day,_,Townsperson_Name,Communicated_Probability,0);
	   	.print(Me, " Voted on Townsperson_Name = ", Townsperson_Name);
	   	.send(game_coordinator, tell, voted_to_eliminate(Day, Me, Townsperson_Name));	
	   }.
	
/* Wake up in the morning */
+day(Day)
	<- .my_name(Me);
	   .findall(X, townsperson(X, _), Xs);
	   .findall(Probability, townsperson(_, Probability), Probabilities);
	   .max(Probabilities, Prob);
	   ?townsperson(Player, Prob);
	   .print(Me, " voted on " , Player);
	   .send(game_coordinator, tell, voted_to_lynch(Day, Me, Player));
	   /* Tell everyone else who the player is voting for */
	   .findall(Name, townsperson(Name,_), Townspersons);
	   .findall(Werewolf, werewolf(Werewolf), Werewolves);
	   .send(Townspersons, tell, voted_to_lynch(Day, Me, Player));
	   .send(Werewolves, tell, voted_to_lynch(Day, Me, Player));
	   /* Necessary to interact with negotiating agents */
	   .findall(Player_Name, player(Player_Name), Players);
	   .send(Players, tell, vote_for(Day, Me, Player, -1));
	   .findall(Werewolf, werewolf(Werewolf), Werewolves);
	   .send(Werewolves, tell, vote_for(Day, Me, Player, -1)).
	   

	   
/* Update probabilities of eliminate a werewolf*/	  
    
/* I am being accused  */    
+voted_to_lynch(_,Accuser, Accused)
	: my_name(Accused) & townsperson(Accuser, Probability) & Probability < 0.9
	<- 	UpdatedProbability = Probability + 0.1;
		.abolish(townsperson(Accuser, _));
		+townsperson(Accuser, UpdatedProbability);
		/* Add thought proccess to the gui */
	   .my_name(Me);
	   update_beliefs_in_townsfolk(Me, Accuser, UpdatedProbability);
	   add_player_thought(Me, Accuser, " has voted to lynch ", Accused, "so it is possible that he knows that he is a werewolf").

/* A werewolf as been accused */		
+voted_to_lynch(_, Accuser, Accused)
	: werewolf(Accused) & townsperson(Accuser, Probability) & Probability < 0.8
	<- 	UpdatedProbability = Probability + 0.2;
		.abolish(townsperson(Accuser, _));
		+townsperson(Accuser, UpdatedProbability);
		/* Add thought proccess to the gui */
		.my_name(Me);
	   	update_beliefs_in_townsfolk(Me, Accuser, UpdatedProbability);
	   	add_player_thought(Me, Accuser, " has voted to lynch me, so it is possible that he knows that I am a werewolf").	
				   
/* a townsperson accuse another one */	
+voted_to_lynch(_, Accuser, Accused)
	: townsperson(Accused,AccusedProb) & townsperson(Accuser,AccuserProb) & AccusedProb > 0.1 & AccuserProb > 0.1
	<-  UpdatedProbability = AccuserProb - 0.1;
		.abolish(townsperson(Accuser, _));
		+townsperson(Accuser, UpdatedProbability);
		NewProbability = AccusedProb - 0.1;
		.abolish(townsperson(Accused, _));
		+townsperson(Accused, NewProbability);
		/* Add thought proccess to the gui */
		.my_name(Me);	
		update_beliefs_in_townsfolk(Me, Accuser, UpdatedProbability);
		update_beliefs_in_townsfolk(Me, Accused, NewProbability);
		add_player_thought(Me, Accuser, " has voted to lynch ", Accused, "so it is possible that he believes that ", Accused ," is a werewolf, so i should let him believe that").			   

			   
/* Remove eliminated player from database */
+dead(Day, Period, Player, Role)
	: alive & .my_name(Player)
	<- -alive.
+dead(Day, Period, Player, werewolf)
	: alive
	<- .print(Player, " has died.");
	   .abolish(werewolf(Player));
	   .my_name(Me);
	   .send(game_coordinator, tell, ready(Day, Period, Me)).
+dead(Day, Period, Player, _)
	: alive
	<- .print(Player, " has died.");
	   .abolish(townsperson(Player, _));
	   .abolish(player(Player));
	   .my_name(Me);
	   .send(game_coordinator, tell, ready(Day, Period, Me)).
	   
/* Required for interoperability */
+vote_for_in_exchange(Day, Accuser, Accused, Promised)
	<- /* Reject the plan straight away */
	   .my_name(Me);
	   .send(Accuser, tell, reject_vote_for_in_exchange(Day, Me, Accused, Promised)).
