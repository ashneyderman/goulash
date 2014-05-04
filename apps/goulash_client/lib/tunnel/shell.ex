defmodule Tunnel.Shell do

    def start(Tunnel.Cli.Parameters[] = params) do
        if params.interactive do
            interactive(params)
        else
            IO.puts "Tests are running. Will terminate in #{params.duration} seconds ..."
            Process.send_after(Process.self(), :timesup, params.duration * 1000)
            timed(params)
        end 
    end
    def start(p) do
        IO.puts "Tunnel.Shell.start ..."
        IO.inspect p
    end

    def timed(Tunnel.Cli.Parameters[] = params) do
        receive do
            :timesup ->
                IO.puts "Good bye!"
                System.halt(0)
            _ ->
                timed(params)
        end
    end  

    def interactive(Tunnel.Cli.Parameters[] = params) do
        IO.write :standard_io, "goulash> "
        (IO.read :standard_io, :line) |> create_cmd |> run
        IO.puts ""
        interactive(params)
    end

    def run(:help) do
        IO.puts "
h/help  - displays this help
i/info  - show info
s/stats - displays stats
q/quit  - quit application
"
    end

    def run(:info) do
        IO.puts "information will be collected and printed here"
    end

    def run(:stats) do
        IO.puts "stats will be printed here" 
    end

    def run(:quit) do
        IO.puts "Good bye!"
        System.halt(0) 
    end

    defp create_cmd(cmd) do
        case cmd do
            "help\n"  -> :help
            "h\n"     -> :help
            "info\n"  -> :info
            "i\n"     -> :info
            "stats\n" -> :stats
            "s\n"     -> :stats
            "quit\n"  -> :quit
            "q\n"  -> :quit
            _ -> :help
        end
    end

end