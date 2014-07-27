defmodule Goulash.AccClient do
    @moduledoc ~S"""
    Module is used only for testing. It has no practical use other than 
    provide trace-ability of the calls to the client module.
    """
    @behaviour Goulash.ClientBehaviour

    def prep(_state,_params) do
        {:ok, [:prep]}
    end
    
    def start(state) do
        {:ok, [:start|state]}
    end

    def pause(state) do
        {:ok, [:pause|state]}
    end
    
    def shutdown(state) do
        {:ok, [:shutdown|state]}
    end

    def on_event(state, event) do
        {:ok, [{:event, event} | state]}
    end

end