defmodule Goulash.Control do
    use Application
    
    def start do
        Application.start :elixir
        Application.start :goulash_control
    end

    def start(_type, _args) do
        :supervisor.start_link({:local, Goulash.ControlSup}, Goulash.ControlSup, [])
    end
    
end
