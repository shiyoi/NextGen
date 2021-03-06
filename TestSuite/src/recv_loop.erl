-module(recv_loop).

-export([
    recv_loop/3
    ]).

-include("state.hrl").
-include("protocol.hrl").

-define(TIMEOUT, 200).

recv_loop(Owner, Socket, #recv_state{id=Id, bytes_recv=BytesRecv,
    cmds_recv=CmdsRecv} = State) ->
    % Since we don't need flow controler in recv loop whe call it before
    % data is received.
    %io:format("Setting socket options {active, once}.~n"),
    inet:setopts(Socket, [{active, once}]),
    receive 
        {get_state} ->
            Owner ! State;
        {tcp, Socket, <<?NOTIFY_PONG, BinTime/binary>> = Data} ->
            TimeStamp = binary_to_term(BinTime),
            Diff = timer:now_diff(now(), TimeStamp),
            %io:format("Got ping ms: ~p.~n", [Diff/1000]),
            NewBytesRecv = BytesRecv + byte_size(Data) + 2,
            recv_loop(Owner, Socket, State);
        {tcp, Socket, <<?OBJ_DIR, IdLen/integer, Id:IdLen/binary, 
            X/little-float, Y/little-float, Z/little-float, 
            BinTime/binary>> = Data} ->
            Time = binary_to_term(BinTime),
            Diff = timer:now_diff(now(), Time),
            %io:format("OBJ_DIR ms: ~p.~n", [Diff/1000]),
            NewBytesRecv = BytesRecv + byte_size(Data) + 2,
            recv_loop(Owner, Socket, State);
        {tcp, Socket, <<?OBJ_SPEED, IdLen/integer, Id:IdLen/binary,
            Speed/little-float, 
            BinTimeStamp/binary>> = Data} ->
            TimeStamp = binary_to_term(BinTimeStamp),
            Diff = timer:now_diff(now(), TimeStamp),
            NewBytesRecv = BytesRecv + byte_size(Data) + 2,
            %io:format("OBJ_SPEED ms: ~p.~n", [Diff/1000]),
            recv_loop(Owner, Socket, State);
        {tcp, Socket, Data} ->
            NewBytesRecv = BytesRecv + byte_size(Data) + 2,
            recv_loop(Owner, Socket, 
                State#recv_state{bytes_recv=NewBytesRecv, 
                    cmds_recv=CmdsRecv + 1});
        Other ->
            error_logger:error_report([{unknown_data, Other}])
    after
        ?TIMEOUT ->
            recv_loop(Owner, Socket, State)
    end.
        
