defmodule Tunnel.Cli do

    alias Goulash.InstanceSup, as: S
    alias Goulash.InstanceServer, as: N
    alias Goulash.InstanceServer.Config, as: ICfg
    alias Goulash.ClientBehaviour.Config, as: CCfg

    def main(args \\ System.argv) do
        run(args)
    end

    @doc """
    Test doc
    """
    def run(argv) do
        argv
        |> parse_args
        |> process
        |> Tunnel.Shell.start
    end

    @doc """
    Test doc
    """
    def parse_args(argv) do
        {opts, _args, _invalids} = OptionParser.parse(argv,
                                    switches: [ 
                                        help: :boolean,
                                        verbose: :boolean,
                                        hostname: :string,
                                        port: :integer,
                                        tunnels: :integer,
                                        rate: :integer,
                                        duration: :integer,
                                        interactive: :boolean],
                                    aliases: [ 
                                        h: :help,
                                        v: :verbose,
                                        s: :hostname,
                                        t: :tunnels,
                                        p: :port,
                                        r: :rate,
                                        d: :duration,
                                        i: :interactive ])

        #IO.puts "Opts: #{opts}"
        if opts[:help] do
            usage()
            System.halt(0)
        end

        opts
    end

    def process(params) do
        tparams = struct(Tunnel.Parameters, params)
        session_ids = generate_session_ids(tparams.tunnels)

        lega_cfg = %ICfg{name: "lega_instance"}
        legb_cfg = %ICfg{name: "legb_instance"}

        {:ok, lega_instance} = S.register_new(lega_cfg)
        {:ok, legb_instance} = S.register_new(legb_cfg)

        N.start_in_vm(lega_instance)
        N.start_in_vm(legb_instance)

        Enum.each(session_ids, fn(session_id) ->
            {:ok, _} = N.prep_clients(
                        lega_instance, 
                        %CCfg{
                            client_module: Tunnel.Client, 
                            params: Dict.put(Map.to_list(tparams), :session_id, session_id)},
                        1)
            {:ok, _} = N.prep_clients(
                        legb_instance, 
                        %CCfg{
                            client_module: Tunnel.Client, 
                            params: Dict.put(Map.to_list(tparams), :session_id, session_id)},
                        1)
            end)

        N.start_clients(lega_instance)
        N.start_clients(legb_instance)
        
        tparams
    end

    # helpers
    defp generate_session_ids(0) do
        []
    end
    defp generate_session_ids(number) do
        [:uuid.to_string(:uuid.uuid4()) ++ ':test' | generate_session_ids(number-1)]
    end

    defp usage() do
        IO.puts """
NAME: 

ts_client - executes tunnel clients against a particular tunnel server

SYNOPSIS:

ts_client [--help | -h]
ts_client [--verbose | -v]
          [--hostname | -s <hostname>]
          [--port | -p <port>]
          [--tunnels | -t <no. of tunnels>]
          [--rate | -r <rate>]
          [--duration | -d <seconds>]
          [--interactive | -i]

DESCRIPTION:

Allows to start a number of cleints/channels towards the tunnel server. 

OPTIONS:

--verbose 
    Turns verbosity of the logs a few notches up

--hostname
    Hostname of the target tunnel server. Defaults to localhost

--port
    Port on which tnunel server is listening for traffic

--tunnels 
    Number of tunnels to open

--rate
    Rate (in Kb/sec) of the data exchange between the client and 
    the server.

--duration | -d
    Duration of the test run. This option and --interactive option 
    are mutually exclusive. If --interactive is specified this 
    option will be ignored

--interactive | -i
    Indicates interactive mode of the test run. If specified prompt
    will be displayed for user interactions.    
"""
    end

end