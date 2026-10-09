%% TCP quiz server: sends questions, accepts answers, reports results

-module(server).
-export([start/0, start/1]).

-define(PORT, 8080).
-define(QUESTION, "Capital of France?").
-define(OPTIONS, ["Paris", "London", "Berlin"]).
-define(CORRECT, 1).

start() ->
    start(?PORT).

start(Port) ->
    {ok, Listen} = gen_tcp:listen(Port, [binary, {packet, line}, {reuseaddr, true}, {active, false}]),
    io:format("[server] listening on port ~p~n", [Port]),
    Parent = self(),
    QuizPid = spawn(fun() -> quiz_loop(Parent, []) end),
    accept_loop(Listen, QuizPid).

accept_loop(Listen, QuizPid) ->
    case gen_tcp:accept(Listen) of
        {ok, Socket} ->
            Peer = case inet:peername(Socket) of
                {ok, {Addr, Port}} -> lists:flatten(io_lib:format("~p:~p", [Addr, Port]));
                _ -> "unknown"
            end,
            io:format("[server] client connected: ~s~n", [Peer]),
            QuizPid ! {register, self(), Socket},
            Pid = spawn(fun() -> client_loop(Socket, QuizPid) end),
            QuizPid ! {set_handler, Pid},
            accept_loop(Listen, QuizPid);
        {error, Reason} ->
            io:format("[server] accept error: ~p~n", [Reason])
    end.

client_loop(Socket, QuizPid) ->
    case gen_tcp:recv(Socket, 0) of
        {ok, Line} ->
            Line2 = string:trim(binary_to_list(Line)),
            case Line2 of
                "" -> client_loop(Socket, QuizPid);
                "QUIT" ->
                    io:format("[server] client sent QUIT~n"),
                    QuizPid ! {unregister, self()},
                    gen_tcp:close(Socket),
                    ok;
                _ ->
                    QuizPid ! {answer, self(), Line2},
                    client_loop(Socket, QuizPid)
            end;
        {error, closed} ->
            io:format("[server] client disconnected~n"),
            QuizPid ! {unregister, self()},
            ok;
        {error, _} ->
            QuizPid ! {unregister, self()},
            ok
    end.

quiz_loop(Parent, Clients) ->
    receive
        {register, _From, Socket} ->
            quiz_loop(Parent, [{Socket, undefined} | Clients]);
        {set_handler, Pid} ->
            NewClients = case Clients of
                [{Sock, undefined} | Rest] -> [{Sock, Pid} | Rest];
                _ -> Clients
            end,
            case NewClients of
                [{_Sock, _Pid} | _] when length(NewClients) =:= 1 ->
                    send_question(NewClients),
                    spawn(fun() -> timer:sleep(10000), Parent ! timeout end);
                _ -> ok
            end,
            quiz_loop(Parent, NewClients);
        {answer, Pid, Answer} ->
            handle_answer(Pid, Answer, Clients),
            quiz_loop(Parent, Clients);
        {unregister, Pid} ->
            NewClients = [C || {_, P} = C <- Clients, P =/= Pid],
            quiz_loop(Parent, NewClients);
        timeout ->
            io:format("[server] round finished~n"),
            quiz_loop(Parent, Clients)
    end.

send_question(Clients) ->
    Question = ?QUESTION,
    Options = ?OPTIONS,
    Msg = ["QUESTION: ", Question, "\n" |
           [io_lib:format("  ~p) ~s~n", [I, lists:nth(I, Options)]) || I <- lists:seq(1, length(Options))]],
    Text = iolist_to_binary(Msg),
    [gen_tcp:send(S, Text) || {S, _} <- Clients],
    io:format("[server] question sent: ~s~n", [Question]).

handle_answer(_Pid, Answer, Clients) ->
    Correct = case (try list_to_integer(Answer) catch _:_ -> invalid end) of
        ?CORRECT -> true;
        _ -> false
    end,
    ResultMsg = case Correct of
        true -> "Correct!\n";
        false -> "Wrong.\n"
    end,
    BroadcastMsg = iolist_to_binary([ResultMsg,
        io_lib:format("Correct answer: ~p) ~s~n", [?CORRECT, lists:nth(?CORRECT, ?OPTIONS)])]),
    [gen_tcp:send(S, BroadcastMsg) || {S, _} <- Clients],
    io:format("[server] answer received: ~s (~s)~n",
              [Answer, case Correct of true -> "correct"; false -> "wrong" end]).