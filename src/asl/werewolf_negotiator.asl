/* Initial beliefs */
alive.

/* Rules */
finished_negotiations(Day) :-
	.count(utility(Day, _, _, _, _), CntNegotiations) &
	.count(player(_), CntTownsfolk) &
	.count(werewolf(_), CntWerewolves) &
	CntPlayers = CntTownsfolk + CntWerewolves &
	//.findall(Name, utility(Day, _, Name, _, _), Names) &
	//.print("(CntNegotiations -1)=", CntNegotiations - 1, " CntPlayers=", CntPlayers, " Names=", Names) &
	CntNegotiations - 1 == CntPlayers.

all_werewolves_comunicated(Day) :-
	 .count(townsperson_to_eliminate(Day,_,_,_,_), CntVotes) &
	 .count(werewolf(_), CntWerewolves) &
	 .print("Cntvotes = ", CntVotes, " CntWerewolves = ", CntWerewolves) &
	 CntVotes == CntWerewolves.
 	

/* Initial goals */
!join_game(game_coordinator).

/* Plan */
+!join_game(Coordinator)
	: .my_name(Me)
	<- .send(Coordinator, tell, role(werewolf, Me)).
	
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
	<-	+townsperson(Player, 0.0);
		.print("I've learned that ", Player, " is playing the game.").
	
/*
 * Game loop
 */
	
/* Wake up during the night*/
/* +night(Day)
	: .random(N) & N >= 0.1
	<- .my_name(Me);
	   .print(Me, " wakes up.");
	   .findall([Name, Probability], townsperson(Name, Probability), Probabilities);
	   lib.select_max_or_random(Probabilities, Player);
	   .send(game_coordinator, tell, voted_to_eliminate(Day, Me, Player)). */
	  
/* Sometimes vote sub-optimally to avoid locks */
/* +night(Day)
	<- .my_name(Me);
	   .findall(Name, player(Name), Players);
	   werewolves_of_millers_hollow.actions.random_player(Players, Player);
	   .send(game_coordinator, tell, voted_to_eliminate(Day, Me, Player)). */
	   
/* Wake up during the night*/
+night(Day)
	: .random(N) & N > 0.1
	<- .my_name(Me);
	   .print(Me, " wakes up.");
	   .findall(Probability, townsperson(_, Probability), Probabilities);
	   .max(Probabilities, Prob);
	   .print("My max: ", Prob);
	   ?townsperson(Name, Prob);
	   .findall(Werewolf_Name, werewolf(Werewolf_Name), Werewolves);
	   .length(Werewolves, CntWerewolves);
	   if (CntWerewolves == 0)
	   {
	   	 .print("second place CntWerewolves = ", CntWerewolves, " CntVotes = ", CntVotes);	
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
	   
/* Update probabilities of eliminate a werewolf*/	
    
/* I am being accused  */    
+voted_to_lynch(_,Accuser, Accused)
	: my_name(Accused)
	<- ?townsperson(Accuser, Probability);
	   UpdatedProbability = Probability + 0.1;
	   .abolish(townsperson(Accuser, _));
	   +townsperson(Accuser, UpdatedProbability);
	   /* Add thought proccess to the gui */
	   .my_name(Me);
	   update_beliefs_in_townsfolk(Me, Accuser, UpdatedProbability);
	   add_player_thought(Me, Accuser, " has voted to lynch ", Accused, "so it is possible that he knows that he is a werewolf").

/* A werewolf as been accused */		
+voted_to_lynch(_, Accuser, Accused)
	: werewolf(Accused)
	<- ?townsperson(Accuser, Probability);
	   UpdatedProbability = Probability + 0.2;
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

/* Negotiation
 * The strategy of the werewolves during the negotiation periods is to convince the other
 * players that some townsfolk are actually werewolves.
 */

/* Wake up in the morning */
+day(Day)
	<- .my_name(Me);
	   .print(Me, " wakes up.");
	   !negotiate(Day).
	
/* Negotiate */
+!negotiate(Day)
	/* TODO(jp): Precondition to choose this plan over the others */
	<- !appeal_to_authority(Day).
	
/*
 * Appeal to authority 
 */
	
/* Start an appeal to authority */
+!appeal_to_authority(Day)
	<- .my_name(Me);
	   /* Select the player that is most suspicious of the werewolves */
	   .findall(Probability, townsperson(_, Probability), Probabilities);
	   .max(Probabilities, Prob);
	   ?townsperson(Player, Prob);
	   /* Ask other players to vote for someone */
	   .findall(Name, player(Name), Players);
	   .send(Players, tell, vote_for(Day, Me, Player, Prob));
	   .findall(Werewolf, werewolf(Werewolf), Werewolves);
	   .print("Sending vote for to Werewolves=", Werewolves);
	   .send(Werewolves, tell, vote_for(Day, Me, Player, Prob));
	   /* Estimate the utility of its own plan */
	   Utility = Prob;
	   +utility(Day, appeal_to_authority, Me, Player, Utility);
	   !decide(Day).

/* Stub for non-negotiating agents */
+vote_for(Day, Accuser, Accused, -1)
	<- +utility(Day, stub, Accuser, Accused, -100.0);
	   !decide(Day).

/* When receiving a request to vote for someone */
+vote_for(Day, Accuser, Accused, AccuserCertainty)
	: /* If the player is not the accuser or being accused */
	  not .my_name(Accused) & not .my_name(Accuser) &
	  /* And the accused is not a werewolf */
	  not werewolf(Accused)
	<- /* Estimate the utility of this plan */
	   ?townsperson(Accused, Distrust);
	   Utility = (Distrust + AccuserCertainty) / 2;
	   +utility(Day, appeal_to_authority, Accuser, Accused, Utility);
	   /* Make a decision */
	   !decide(Day).

/* When receiving a request to vote that is not good */
+vote_for(Day, Accuser, Accused, AccuserCertainty)
	<- +utility(Day, appeal_to_authority, Accuser, Accused, -1.0);
	   !decide(Day).
	   
/* 
 * Promise of future reward 
 */
 
/* When receiving a request to vote that is not good */
+vote_for_in_exchange(Day, Accuser, Accused, Promised)
	<- +utility(Day, promise_of_future_reward, Accuser, Accused, -1.0);
	   /* Reject the plan straight away */
	   .my_name(Me);
	   .send(Accuser, tell, reject_vote_for_in_exchange(Day, Me, Accused, Promised));
	   !decide(Day).
	   
/* Make a decision */
+!decide(Day) : not finished_negotiations(Day).
+!decide(Day)
	: finished_negotiations(Day)
	<- .my_name(Me);
	   /* Select the plan with the most utility */
	   .findall(Utility, utility(Day, _, _, _, Utility), Utilities);
	   lib.max_utility(Utilities, MaxUtility);
	   ?utility(Day, _, Accuser, Accused, MaxUtility);
	   /* Vote to lynch the player */
	   add_player_thought(Me, Accuser, " has told me that ", Accused, " is a werewolf. Let him keep believing that.");
	   .send(game_coordinator, tell, voted_to_lynch(Day, Me, Accused));
	   /* Tell everyone else who the player is voting for */
	   .findall(Name, player(Name), Players);
	   .send(Players, tell, voted_to_lynch(Day, Me, Accused)).