defmodule Tunnel.State do
    
    defstruct verbose: :quite,
             hostname: :undefined,
                 port: :undefined,
                 rate: :undefined,
           session_id: :undefined,
               socket: :undefined,
            timer_ref: :undefined,
     ep_info_received: false,
       ep_info_buffer: <<>>

end
