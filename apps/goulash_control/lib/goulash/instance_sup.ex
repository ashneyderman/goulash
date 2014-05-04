defmodule Goulash.InstanceSup do
    use Supervisor.Behaviour

    @regname Goulash.InstanceSup
    
    @moduledoc """
    When tests run they spawn instanes where goulash clients are 
    spawned. The spawned representation of that instance is 
    supervised by this module.
    """

    @doc """
    TODO: needs docs
    """
    #TODO - needs spec
    def start_link() do
        :supervisor.start_link({:local, @regname}, __MODULE__, [])    
    end

    @doc """
    TODO: needs docs
    """
    #TODO - needs spec
    def register_new(config) do
        :supervisor.start_child(@regname, [config])
    end

    # callbacks
    @doc """
    TODO: needs docs
    """
    #TODO - needs spec
    def init(args) do
        tree = [ worker(Goulash.InstanceServer, args) ]
        supervise tree, strategy: :simple_one_for_one
    end

end