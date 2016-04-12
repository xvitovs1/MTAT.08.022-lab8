-module(authclient).
-export([start/0, auth/2]).
-import(crypto, [hash/2]).

-define(BYTE,8/signed-big-integer).
-define(INT,32/signed-big-integer).
-define(LONG,64/signed-big-integer).

start() ->
  io:format("Started~n"),
  auth("localhost", 5000).

auth(Host, Port) ->
  case gen_tcp:connect(Host, Port, [binary, {packet,4}]) of
    {ok, Socket} ->
      send(Socket, {login,"Oleg"}),
      process(Socket);
    {error, Reason} ->
      io:format("Error connecting to server: ~s~n",[Reason]),
      exit(1)
  end.

process(Socket) ->
  receive
    {tcp, _, Bin} ->
      % PROCESS MESSAGES HERE
      Msg = decode(Bin),
      case Msg of
        {params, Salt} ->
          case string:len(Salt) of
            0 -> exit(1);
            _Else -> true
          end,
          Digest = crypto:hash(sha, Salt++"mypassword"),
          send(Socket, {auth, Digest}),
          process(Socket);
        {result, Success, Error} ->
          case Success of
            true ->
              io:format("Login successful.~n");
            false -> io:format("Login was not successful: ~s ~n",[Error])
          end
      end
  after (5000) ->
          io:format("Timeout for server to respond.~n"),
          exit(1)
  end.

send(Socket, Msg) ->
  Data = list_to_binary(encode(Msg)),
  case gen_tcp:send(Socket, Data) of
    {error,Reason} -> io:format("Error sending message: ~s~n",[Reason]),
                      exit(1);
    _Else -> true
  end.

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
  case Bin of
    <<MType: ?INT, Content/binary>> ->  case MType of
                                          1 ->
                                            case Content of
                                              <<DLen: ?INT, Salt:DLen/binary>> -> {params, binary_to_list(Salt)};
                                              _Else-> io:format("Wrong format of message.~n"),
                                                      exit(1)
                                            end;
                                          3 ->
                                            case Content of
                                              <<Success: ?BYTE, SLen:?INT, Error:SLen/binary>> -> {result, Success==1, binary_to_list(Error)};
                                              _Else -> io:format("Wrong format of message.~n"),
                                                       exit(1)
                                            end;
                                          Other ->
                                            io:format("Unknown type of message: ~d~n",Other),
                                            exit(1)
                                        end;
   _Else -> io:format("Wrong format of message.~n")
 end.
