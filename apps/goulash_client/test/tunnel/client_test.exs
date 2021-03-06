defmodule Tunnel.ClientTest do
    use ExUnit.Case

    alias Goulash.InstanceSup, as: S
    alias Goulash.InstanceServer, as: N
    alias Goulash.InstanceServer.Config, as: ICfg
    alias Goulash.ClientBehaviour.Config, as: CCfg

    test "Simple client creation" do
        instance_cfg = %ICfg{name: "test1"}

        {:ok, instance} = S.register_new(instance_cfg)
        assert :inactive === N.info(instance).status
        assert :ok === N.start_in_vm(instance)
        client_cfg = %CCfg{client_module: Tunnel.Client, 
                                  params: [test0: "test0", 
                                           test1: "test1"]}
        {:ok, _} = N.prep_clients(instance, client_cfg, 5)
        clients = N.all_clients(instance)
        assert 5 === Enum.count(clients)
    end

end