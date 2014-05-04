defmodule Mix.Tasks.Goulash do
    use Mix.Task

    def run(args) do   
        IO.puts "Goulash task was called with arguments: #{args}"
    end

end