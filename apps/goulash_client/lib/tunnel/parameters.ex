defmodule Tunnel.Parameters do
    @derive Access
    defstruct verbose: false,
              hostname: "localhost",
              port: 29000,
              tunnels: 1,
              rate: 10,
              duration: 60,
              interactive: false

end