defmodule Goulash.InstanceSup do
    @moduledoc """
    This module helps spawn multiple instances of `Goulash.InstanceServer`
    """
    use Supervisor

    ## APIs
    @doc """
    """
    def start_link() do
        :supervisor.start_link({:local, __MODULE__}, __MODULE__, [])    
    end

    @doc """
    Add instance of `Goulash.InstanceServer` to the supervision tree.
    """
    @spec register_new(config :: Goulash.InstanceConfig.t) ::
        {:ok, pid()}        
    def register_new(config) do
        :supervisor.start_child(__MODULE__, [config])
    end

    # supervisor callbacks
    def init(args) do
        tree = [ worker(Goulash.InstanceServer, args, [restart: :temporary]) ]
        supervise tree, strategy: :simple_one_for_one
    end
end