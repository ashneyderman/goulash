defmodule Goulash.ClientBehaviour do
    @moduledoc ~S"""
    Defines goulash client's callbacks. 

    Goulash integrates client instances via a series of life-cycle callbacks.
    Internally goulash maintains a FSM to keep track of clients' states. When
    changes to the state occur a module that implements client-specific behavior
    is called with an appropriate callback.

    The following are the life-cycle callbacks that are expected to be 
    implemented by the outside modules to plugin into goulash runtime:
        * prep     - called when goulash determines that a client will have 
                     to be used at some point of the test/program run
        * start    - called when goulash indcates to the client that its main 
                     loop is ready to begin
        * pause    - called when goulash wants a client pause the client's 
                     main loop
        * shutdown - called when goulash needs to stop the execution of the 
                     particular client
    """
    use Behaviour

    defmodule Config do
        @derive Access
        defstruct client_module: :undefined,
                         params: []
    end

    @type property :: atom() | tuple()

    @doc ~S"""
    Prepare a client.
    """
    defcallback prep(state :: term(), options :: list(property)) :: 
        {:ok, new_state :: term()} | 
        {:error, reason :: term()}

    @doc ~S"""
    Start the client.
    """
    defcallback start(state :: term()) :: 
        {:ok, new_state :: term()} | 
        {:error, reason :: term()}

    @doc ~S"""
    Stop the client.
    """
    defcallback pause(state :: term()) :: 
        {:ok, new_state :: term()} | 
        {:error, reason :: term()}

    @doc ~S"""
    Shutdown the client.
    """
    defcallback shutdown(state :: term()) :: 
        {:ok, new_state :: term()} | 
        {:error, reason :: term()}


    @doc ~S"""
    On async event handler
    """
    defcallback on_event(state :: term(),
                         event :: term()) :: 
        {:ok, new_state :: term()} | 
        {:error, reason :: term()}

end
