defmodule Goulash.ControlSup do
    use Supervisor

    def init(_args) do
        # IO.puts "Goulash.ControlSup.init"
        tree = [ supervisor(Goulash.InstanceSup, []) ]
        supervise(tree, strategy: :one_for_one)
    end

end