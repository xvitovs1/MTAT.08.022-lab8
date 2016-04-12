-module(task2).
-export([start/0, auth/2]).
-import(crypto, [hash/2]).

-define(BYTE,8/signed-big-integer).
-define(INT,32/signed-big-integer).
-define(LONG,64/signed-big-integer).

start() ->
  io:format("Started~n"),
  auth("localhost", 5000).

auth(Host, Port) ->
  {ok, Socket} = gen_tcp:connect(Host, Port, [binary, {packet,4}]),
  send(Socket, {login,"Oleg"}),
  process(Socket).

process(Socket) ->
  receive
    {tcp, _, Bin} ->
      % PROCESS MESSAGES HERE
      Msg = decode(Bin),
      case Msg of
        {params, Salt} ->
          Digest = crypto:hash(sha, Salt++"mypassword"),
          send(Socket, {auth, Digest}),
          process(Socket);
        {result, Success, Error} ->
          case Success of
            true -> io:format("Login successful.~n");
            false -> io:format("Login was not successful: ~s ~n",[Error])
          end
      end
  end.

send(Socket, Msg) ->
  Data = list_to_binary(encode(Msg)),
  gen_tcp:send(Socket, Data).

encode(Msg) ->
  case Msg of
    {login, Username} ->
      Size = length(Username),
      [<<0:?INT, Size:?INT>>, Username];
    {auth, Digest} ->
      Size = size(Digest),
      [<<2:?INT, Size:?INT>>, Digest]
  end.

decode(Bin) ->
  <<MType: ?INT, Content/binary>> = Bin,
  case MType of
    1 ->
      <<DLen: ?INT, Salt:DLen/binary>> = Content,
      {params, binary_to_list(Salt)};
    3 ->
      <<Success: ?BYTE, SLen:?INT, Error:SLen/binary>> = Content,
      {result, Success==1, binary_to_list(Error)}
  end.

