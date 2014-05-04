defmodule Goulash.ClientSup do
    use Supervisor.Behaviour

    @spec start_link(config :: Goulash.ClientBehavior.ClientConfig.t) :: 
            {:ok, pid()} | 
            {:error, term()}
    def start_link(config) do
        :supervisor.start_link(__MODULE__, config)
    end

    def init(config) do
        module = config.client_module
        tree = [ worker(module, [], [function: :prep, 
                                      modules: [module]]) ]
        supervise(tree, strategy: :simple_one_for_one)
    end

end