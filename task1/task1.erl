-module(task1).
-export([loop/1]).
-export([loopConf/1]).

loop(X) ->
   receive
	{add, V} ->
	  loop(X+V);
	{get, ClientPID} ->
	  io : format ("~p~n",[X]),
  	  ClientPID ! X,
	  loop(X);
	{stop} ->
	  loopConf(X);
        Other ->
          loop(X)
   end.

loopConf(X) ->
   receive
	{start} ->
	  loop(X); % Here I can start either from 0 or continue from X
        Other ->
          loopConf(X)
   end.



