# GoulashControl

** TODO: Add description **


Notes
18:08:26 goulash_control > iex --sname "text0" --cookie "test" --erl "-rsh ssh" -S mix 
Erlang R16B02 (erts-5.10.3) [source] [smp:8:8] [async-threads:10] [hipe] [kernel-poll:false]

Interactive Elixir (0.12.5) - press Ctrl+C to exit (type h() ENTER for help)
iex(text0@dhcp17de)1> {:ok, instance} = Goulash.InstanceSup.register_instance(Goulash.InstanceServer.Config.new(name: "text1", init_params: [hostname: "localhost"]))
{:ok, #PID<0.68.0>}
iex(text0@dhcp17de)2> Goulash.InstanceServer.start_slave(instance) 

    Host: localhost
    Instance: text1
    Args: -setcookie test

ssh: connect to host localhost port 22: Connection refused

BREAK: (a)bort (c)ontinue (p)roc info (i)nfo (l)oaded
       (v)ersion (k)ill (D)b-tables (d)istribution
a
18:09:04 goulash_control > iex --sname "text0" --cookie "test" --erl "-rsh ssh" -S mix 
Erlang R16B02 (erts-5.10.3) [source] [smp:8:8] [async-threads:10] [hipe] [kernel-poll:false]

Interactive Elixir (0.12.5) - press Ctrl+C to exit (type h() ENTER for help)
iex(text0@dhcp17de)1> {:ok, instance} = Goulash.InstanceSup.register_instance(Goulash.InstanceServer.Config.new(name: "text1", init_params: [hostname: "alexmac"]))
{:ok, #PID<0.68.0>}
iex(text0@dhcp17de)2>  Goulash.InstanceServer.start_slave(instance) 

    Host: alexmac
    Instance: text1
    Args: -setcookie test

ssh: connect to host alexmac port 22: Connection refused
** (exit) {:timeout, {:gen_server, :call, [#PID<0.68.0>, :start_slave]}}
    (stdlib) gen_server.erl:180: :gen_server.call/2
iex(text0@dhcp17de)2> 
BREAK: (a)bort (c)ontinue (p)roc info (i)nfo (l)oaded
       (v)ersion (k)ill (D)b-tables (d)istribution
a
18:09:47 goulash_control > iex --sname "text0" --cookie "test" --erl "-rsh ssh" -S mix 
Erlang R16B02 (erts-5.10.3) [source] [smp:8:8] [async-threads:10] [hipe] [kernel-poll:false]

Interactive Elixir (0.12.5) - press Ctrl+C to exit (type h() ENTER for help)
iex(text0@dhcp17de)1>  {:ok, instance} = Goulash.InstanceSup.register_instance(Goulash.InstanceServer.Config.new(name: "text1", init_params: [hostname: "dhcp17de"]))
{:ok, #PID<0.68.0>}
iex(text0@dhcp17de)2> Goulash.InstanceServer.start_slave(instance) 

    Host: dhcp17de
    Instance: text1
    Args: -setcookie test

:ok
