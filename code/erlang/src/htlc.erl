%%% --------------------------------------------------------------------
%%% @copyright 2018, Backyard Innovations Pte. Ltd., Singapore.
%%%
%%% Released under the terms of the GNU Affero General Public License
%%% v3.0. See: file LICENSE that came with this software for details.
%%%
%%% This file contains Intellectual Property that belongs to
%%% Backyard Innovations Pte Ltd., Singapore.
%%%
%%% @author Santhosh Raju <santhosh@byisystems.com>
%%% @author Cherry G. Mathew <cherry@byisystems.com>
%%% --------------------------------------------------------------------

%%% --------------------------------------------------------------------
%%% This module implements the State Machine defined in the "Holder
%%% Transmit Life Cycle" TLA+ specification. A diagram of the states and
%%% the transition rules can be found in the DOT specification.
%%%
%%% This Finite State Machine (FSM) is private to the entity who is
%%% involved in a Voucher operation. So the VTP has no visibility of the
%%% the current state of the Entity involved in the Voucher operaton.
%%%
%%% The FSM exclusively tracks the state of the Entity. No other
%%% information is tracked or passed here. Given the "current" state,
%%% and the operation being performed, the FSM accurately gives the
%%% the next state.
%%% --------------------------------------------------------------------
-module(htlc).

-export([init_fsm/1, init/2, prepare/2, abort/2, redeem/2, transfer/2]).

-import(logger,[log/1,log/2,log_final_state/2]). % @todo Use a proper logging framework

%% ---------------------------------------------------------------------
%% Initialize the FSM to a known state for the entity.
%%
%% If an entity's state is not yet defined, you pass in "initialize" as
%% the state to initialize the entity to the starting state
%%
%% The spawned process can then be used to perform transitions in the
%% state machine.
%% ---------------------------------------------------------------------
init_fsm(State) ->
    case State of
	initialize ->
	    spawn(fun() -> initialize() end);
	holding ->
	    spawn(fun() -> holding() end);
	prepared ->
	    spawn(fun() -> prepared() end);
	transferred  ->
	    spawn(fun() -> transferred() end);
	redeemed  ->
	    spawn(fun() -> redeemed() end);
	aborted ->
	    spawn(fun() -> aborted() end);
	_ ->
	    log("[~p] !!! Invalid holder (transmit) state (~p) specified !!!~n", [?MODULE, State])
    end.

%% ---------------------------------------------------------------------
%% Valid operations that can be done on a given state of FSM of the
%% Holder (Transmit) that is defined in the TLA+ and DOT specifications.
%%
%% The variable OpPid is used to refer to the running Pid of the
%% operations.
%% ---------------------------------------------------------------------

%% The function init(), is used when the entity is undefined.
init(FsmPid, State) ->
    log("[~p] Doing init on holder (transmit) in ~p state~n", [?MODULE, State]),
    FsmPid ! {self(), {init, State}},
    receive
	{FsmPid, {init, NextState}} ->
	    NextState
    end.

prepare(FsmPid, State) ->
    log("[~p] Doing prepare on holder (transmit) in ~p state~n", [?MODULE, State]),
    FsmPid ! {self(), {prepare, State}},
    receive
	{FsmPid, {prepare, NextState}} ->
	    NextState
    end.

abort(FsmPid, State) ->
    log("[~p] Doing abort on holder (transmit) in ~p state~n", [?MODULE, State]),
    FsmPid ! {self(), {abort, State}},
    receive
	{FsmPid, {abort, NextState}} ->
	    NextState
    end.

redeem(FsmPid, State) ->
    log("[~p] Doing redeem on holder (transmit) in ~p state~n", [?MODULE, State]),
    FsmPid ! {self(), {redeem, State}},
    receive
	{FsmPid, {redeem, NextState}} ->
	    NextState
    end.

transfer(FsmPid, State) ->
    log("[~p] Doing transfer on holder (transmit) in ~p state~n", [?MODULE, State]),
    FsmPid ! {self(), {transfer, State}},
    receive
	{FsmPid, {transfer, NextState}} ->
	    NextState
    end.

%% ---------------------------------------------------------------------
%% Valid states for a Holder (Transmit) that is defined in the TLA+ and
%% DOT specifications.
%%
%% The variable FsmPid is used to refer to the running Pid of the
%% current state.
%%
%% This is private to the module and is not exposed.
%% ---------------------------------------------------------------------

%% The function initialize(), is used when the entity is undefined.
initialize() ->
    receive
	{OpPid, {init, State}} ->
	    NextState = holding,
	    OpPid ! {self(), {init, NextState}},
	    log("[~p] Initialized holder (transmit) from ~p to ~p~n", [?MODULE, State, NextState]);
	_ ->
	    log("[~p] !!! Invalid operation on initializing holder (transmit) !!!~n", [?MODULE])
    end.

holding() ->
    receive
        {OpPid, {prepare, State}} ->
	    NextState = prepared,
	    OpPid ! {self(), {prepare, NextState}},
	    log("[~p] State of holder (transmit) set from ~p to ~p~n", [?MODULE, State, NextState]);
        {OpPid, {abort, State}} ->
	    NextState = aborted,
	    OpPid ! {self(), {abort, NextState}},
	    log("[~p] State of holder (transmit) set from ~p to ~p~n", [?MODULE, State, NextState]);
        _ ->
            log("[~p] !!! Invalid operation on holding state of holder (transmit) !!!~n", [?MODULE])
    end.

prepared() ->
    receive
        {OpPid, {redeem, State}} ->
	    NextState = redeemed,
	    OpPid ! {self(), {redeem, NextState}},
	    log("[~p] State of holder (transmit) set from ~p to ~p~n", [?MODULE, State, NextState]);
        {OpPid, {transfer, State}} ->
	    NextState = transferred,
	    OpPid ! {self(), {transfer, NextState}},
	    log("[~p] State of holder (transmit) set from ~p to ~p~n", [?MODULE, State, NextState]);
        {OpPid, {abort, State}} ->
	    NextState = aborted,
	    OpPid ! {self(), {abort, NextState}},
	    log("[~p] State of holder (transmit) set from ~p to ~p~n", [?MODULE, State, NextState]);
        _ ->
            log("[~p] !!! Invalid operation on prepared state of holder (transmit) !!!~n", [?MODULE])
    end.

transferred() ->
    receive
        _ ->
            log("[~p] !!! Invalid operation on transferred state of holder (transmit) !!!~n", [?MODULE])
    end.

redeemed() ->
    receive
        _ ->
            log("[~p] !!! Invalid operation on redeemed state of holder (transmit) !!!~n", [?MODULE])
    end.

aborted() ->
    receive
        _ ->
            log("[~p] !!! Invalid operation on aborted state of holder (transmit) !!!~n", [?MODULE])
    end.
