defmodule Goulash.Control.ServerTest do
    use ExUnit.Case

    alias Goulash.ControlServer, as: GServer

    test "server startup" do
        GServer.start_link()
        assert([] === GServer.show_configs)
        load_cfg = GServer.LoadConfig[name: "test", 
                                      description: "test desc", 
                                      total_instances: 23]
        GServer.add_config(load_cfg)
        assert([load_cfg] === GServer.show_configs)
        GServer.stop()
    end

    

end