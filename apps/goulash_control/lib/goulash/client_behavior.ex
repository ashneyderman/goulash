defmodule Goulash.ClientBehavior do
    @moduledoc """
    Behaviour that allows a module to act as Goulash client. To be a goulash
    client one needs to define the callbacks that goualsh invokes as it conducts
    load testing and spawns and stops new clients.

    Lifecyle of goulash consists of four distinct phases

        * prep  - called when goulash determines that a client will have to be 
                  used at some point of the test
        * start - called when goulash wants a client start doing what it needs
                  to do
        * stop  - called when goulash wants a client stop doing what it is doing
        * shutdown - allows client to cleanup after itself
    """
    use Behaviour

    @doc """
    TODO - desribe config record
    """
    defrecord ClientConfig,
        client_module: :undefined,
        params: []

    @type client_ref :: pid() | reference()
    @type property :: atom() | tuple()

    @doc """
    Prepare a client.
    """
    defcallback prep(options :: list(property)) :: {:ok, client_ref} | {:error, term()}

    @doc """
    Start the client.
    """
    defcallback start(client :: client_ref) :: :ok | {:error, term()}

    @doc """
    Stop the client.
    """
    defcallback stop(client :: client_ref) :: :ok | {:error, term()}

    @doc """
    Shutdown the client.
    """
    defcallback shutdown(client :: client_ref) :: :ok | {:error, term()}

end