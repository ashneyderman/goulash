defmodule Tunnel.ClientTest do
    use ExUnit.Case

    alias Goulash.InstanceSup, as: S
    alias Goulash.InstanceServer, as: N
    alias Goulash.InstanceServer.Config, as: InstanceConfig
    alias Goulash.ClientBehavior.ClientConfig, as: ClientConfig

    test "Simple client creation" do
        instance_cfg = InstanceConfig.new(name: "test1")

        {:ok, instance} = S.register_new(instance_cfg)
        assert :inactive === N.info(instance).status
        assert :ok === N.start_in_vm(instance)

        client_cfg = ClientConfig.new(client_module: Tunnel.Client, 
                                      params: [test0: "test0", 
                                               test1: "test1"])
        {:ok, _} = N.prep_clients(instance, client_cfg, 5)

        clients = N.all_clients(instance)
        assert Enum.count(clients) == 5
    end

    



end