defmodule Goulash.ClientSup do
    use Supervisor

    ## -------------------------------------------------------------------------
    ## API functions
    ## -------------------------------------------------------------------------

    @doc """
    TODO - document
    """
    @spec start_link() :: 
            {:ok, pid()} | 
            {:error, term()}
    def start_link() do
        :supervisor.start_link(__MODULE__, [])
    end

    @doc """
    TODO - document
    """
    @spec init_client(supervisor :: pid() | atom(),
                      config :: Goulash.ClientBehaviour.Config.t) ::
            {:ok, pid()} |
            {:stop, term()}
    def init_client(supervisor, %Goulash.ClientBehaviour.Config{} = config) do
        :supervisor.start_child(supervisor,[config])
    end
    
    ## -------------------------------------------------------------------------
    ## supervisor callbacks
    ## -------------------------------------------------------------------------

    def init([]) do
        tree = [ worker(Goulash.Client, [], [restart: :temporary]) ]
        supervise(tree, strategy: :simple_one_for_one)
    end

end