%% TCP-клиент викторины: подключается к серверу, читает вопрос, отправляет ответ

-module(client).
-export([start/0, start/1]).

-define(HOST, "127.0.0.1").
-define(PORT, 8080).

start() ->
    start(?PORT).

start(Port) ->
    {ok, Socket} = gen_tcp:connect(?HOST, Port, [binary, {packet, line}, {active, false}]),
    io:format("[client] connected to ~s:~p~n", [?HOST, Port]),
    %% поток для чтения сообщений от сервера
    Parent = self(),
    Reader = spawn(fun() -> reader_loop(Socket, Parent) end),
    loop(Socket, Reader).

%% цикл чтения с консоли и отправки на сервер
loop(Socket, Reader) ->
    case io:get_line("") of
        eof -> gen_tcp:close(Socket), ok;
        {error, _} -> gen_tcp:close(Socket), ok;
        Line ->
            Trimmed = string:trim(Line),
            case Trimmed of
                "" -> loop(Socket, Reader);
                _ ->
                    gen_tcp:send(Socket, [Trimmed, "\n"]),
                    case Trimmed of
                        "QUIT" -> gen_tcp:close(Socket), ok;
                        _ -> loop(Socket, Reader)
                    end
            end
    end.

%% цикл чтения сообщений от сервера и вывода в консоль
reader_loop(Socket, _Parent) ->
    case gen_tcp:recv(Socket, 0) of
        {ok, Line} ->
            io:format("~s", [Line]),
            reader_loop(Socket, _Parent);
        {error, closed} ->
            io:format("[client] server closed connection~n"),
            ok;
        {error, _} ->
            ok
    end.