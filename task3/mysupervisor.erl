-module(mysupervisor).
-import(authclient, [start/0]).
-export([loop/0]).

loop() ->
  Pid = spawn(authclient, start, []),
  on_exit(Pid).

on_exit(Pid) ->
  spawn(fun() ->
    process_flag(trap_exit , true),
    link(Pid),
    receive
      {'EXIT',Pid,normal} ->
        io:format("exited normally~n");
      {'EXIT',Pid,Why} ->
        io:format("exited with error~n"),
        timer:apply_after(10000,erlang, spawn,[authclient, start, []])
    end
  end).
