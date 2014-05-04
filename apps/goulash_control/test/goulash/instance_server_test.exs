defmodule Goulash.InstanceServerTest do
    use ExUnit.Case

    alias Goulash.InstanceSup, as: S
    alias Goulash.InstanceServer, as: N
    alias Goulash.InstanceServer.Config, as: Cfg
    
    # you can run this test from command line like so:
    # elixir --sname "test" --cookie "test" --erl "-rsh ssh" -S mix test
    # elixir --name "test" --cookie "test" --erl "-rsh ssh" -S mix test
    test "Register instance, start slave and stop instance" do
        assert Node.self() !== :"nonode@nohost", "test has to start in VM that provides -sname or -name parameter"
        assert :nocookie !== Node.get_cookie, "test has to start in VM that sets its cookie (-setcookie parameter)"
        
        config = Cfg.new(name: "test1", 
                         init_params: [
                            hostname: :net_adm.localhost
                         ])

        {:ok, instance} = S.register_new(config)
        assert :inactive === N.info(instance).status, "just registered instance has to be in inactive state" 
        assert :ok === N.start_slave(instance), "starting slave has to be possible"
        assert :active === N.info(instance).status, "after starting slave instance status has to be active"
        assert :ok === N.stop(instance), "stopping slave should be doable"
        assert :inactive === N.info(instance).status, "stopped slave isntance should be in inactive state"
    end

end