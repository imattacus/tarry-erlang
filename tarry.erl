-module(tarry).
-compile(export_all).

start() ->
    [[InitName]|T] = parse_input([]),
    Nodes = [{X, Neighbours} || [X|Neighbours] <- T],
    Pids = [{X, spawn(tarry, node, [X])} || {X, _} <- Nodes],
    lists:map(fun(Node) -> send_neighbours(Node, Pids) end, Nodes),
    {_, InitPid} = lists:keyfind(InitName, 1, Pids),
    InitPid ! {self(), []},
    receive
        {_, Token} -> io:format("~s~n", [string:join(Token, " ")])
    end.

parse_input(Names) ->
    case io:get_line("") of
        eof -> Names;
        Line -> parse_input(Names ++ [string:tokens(Line, " \n")])
    end.

send_neighbours({Node, Neighbours}, Pids) ->
    NeighbourPids = lists:filter(
        fun({Name, _}) -> list_contains(Neighbours, Name) end,
        Pids
    ),

    {_, Pid} = lists:keyfind(Node, 1, Pids),
    Pid ! NeighbourPids.

list_contains(List, N) ->
    lists:foldl(
        fun(M, Sum) -> M or Sum end,
        false,
        lists:map(fun(L) -> L == N end, List)
    ).

node(Name) ->
    receive
        Neighbours -> tarry(Name, Neighbours)
    end.

tarry(Name, Neighbours) ->
    receive
        {Pid, Token} ->
            NeighboursWithoutParent = lists:keydelete(Pid, 2, Neighbours),
            case NeighboursWithoutParent of
                [] -> Pid ! {self(), Token ++ [Name]};
                [{_, NextPid} | T] ->
                    NextPid ! {self(), Token ++ [Name]},
                    tarry(Name, T, Pid)
            end
    end.

tarry(Name, [], Parent) ->
    receive
        {_, Token} -> Parent ! {self(), Token ++ [Name]}
    end;

tarry(Name, [{_, NextPid} | T], Parent) ->
    receive
        {_, Token} ->
            NextPid ! {self(), Token ++ [Name]},
            tarry(Name, T, Parent)
    end.