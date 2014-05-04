defmodule Goulash.ControlSup do
    use Supervisor.Behaviour

    def init(_args) do
        # IO.puts "Goulash.ControlSup.init"
        tree = [ worker(Goulash.ControlServer, []),
                 supervisor(Goulash.InstanceSup, []) ]
        supervise(tree, strategy: :one_for_one)
    end


end