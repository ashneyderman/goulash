defmodule Tunnel.Client do
    @behaviour Goulash.ClientBehaviour
    @send_timeout 15000
    @connect_timeout 10000
    @send_interval 1000

    use GenServer

    defmodule State do
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

    def prep(_, args) do
        {:ok, _tunnel_pid} = result = :gen_server.start_link(__MODULE__, args, [])
        result
    end

    def start(tunnel_pid) do
        :gen_server.call(tunnel_pid, :start)
    end

    def pause(tunnel_pid) do
        :gen_server.call(tunnel_pid, :pause)
    end

    def shutdown(tunnel_pid) do
        :gen_server.call(tunnel_pid, :shutdown)
    end

    def on_event(tunnel_pid,_event) do
        {:ok, tunnel_pid}
    end

    def init(options) do
        {:ok, struct(State, options)}
    end

    def handle_call(:start, _from, %State{} = state) do
        case :gen_tcp.connect(to_char_list(state.hostname), 
                            state.port, 
                            [active: false,
                             mode: :binary,
                             packet: :raw,
                             delay_send: false,
                             send_timeout: @send_timeout,
                             send_timeout_close: false], 
                            @connect_timeout) do
            {:ok, socket} ->
                :ok = start_tunnel(%State{state | socket: socket})
                :inet.setopts(socket, [{:active, :once}])
                tref = Process.send_after(self(), {:send_next_chunk, state.rate}, @send_interval)
                {:reply, {:ok, self()}, %State{state | socket: socket,
                                                       timer_ref: tref}}
            {:error, reason} ->
                {:stop, {:error, reason}, state}
        end
    end

    def handle_call(:pause, _from, %State{} = state) do
        IO.puts "pause call"
        tref = state.timer_ref
        :timer.cancel(tref)
        {:reply, {:ok, self()}, state}
    end

    def handle_call(:shutdown, _from, %State{} = state) do
        IO.puts "shutdown call"
        try do
            :gen_tcp.close(state.socket)
        catch
            _, _ -> 
                :ok
        end
        {:stop, :shutdown, {:ok, self()}, state}
    end

    def handle_call(request, from, %State{} = state) do
        IO.puts "Unhandled call:"
        IO.inspect request
        super(request, from, state)
    end

    def handle_info({:tcp, socket, data}, %State{ep_info_received: false} = state) do
       buffer = state.ep_info_buffer 
       msg = <<buffer :: binary, data :: binary>> 
       {new_ep_info_received, new_ep_info_buffer} = decode_endpoint_info(msg)
       :inet.setopts(socket, [{:active, :once}])
       {:noreply, %State{ state | 
                           ep_info_received: new_ep_info_received,
                           ep_info_buffer: new_ep_info_buffer}}
    end

    def handle_info({:tcp, socket, _}, %State{ep_info_received: true} = state) do
        :inet.setopts(socket, [{:active, :once}])
        {:noreply, state}
    end

    def handle_info({:tcp_closed, _socket}, %State{} = state) do
        tref = state.timer_ref
        :timer.cancel(tref)
        {:stop, :normal, %State{ state | timer_ref: :undefined}}
    end
    
    def handle_info({:send_next_chunk, _}, %State{ep_info_received: false} = state) do
        tref = Process.send_after(self(), {:send_next_chunk, state.rate}, @send_interval)
        {:noreply, %State{ state | timer_ref: tref}}
    end
    
    def handle_info({:send_next_chunk, _}, %State{} = state) do
        tpr = div(1000, @send_interval)
        next_chunk_size = div(state.rate, tpr)
        data_chunk = generate_random_data(next_chunk_size)
        case :gen_tcp.send(state.socket, data_chunk) do
            :ok -> 
                tref = Process.send_after(self(), {:send_next_chunk, state.rate}, @send_interval) 
                {:noreply, %State{state | timer_ref: tref}}
            {:error, reason} ->
                IO.puts "Error sending data for session #{state.session_id}. Error: #{reason}"
                {:stop, reason, state}
        end
    end

    def handle_info(request, %State{} = state) do
        IO.puts "Unhandled info:"
        IO.inspect request
        super(request, state)
    end

    # private helpers
    defp start_tunnel(%State{} = state) do
        {:ok, msg} = :xmlrpc_encode.payload({:call, :start_tunnel, [{:struct, [
                                                                    {:id,state.session_id},
                                                                    {:"listen.endpoint", 'localhost:20000'}
                                                                    ]
                                                                 }]})
        binmsg = :erlang.iolist_to_binary(msg)
        msgsize = :erlang.byte_size(binmsg)
        packet = <<1 :: [size(32), integer], 1 :: [size(32), integer], msgsize :: [size(32), integer], binmsg :: binary>>
        :gen_tcp.send(state.socket,packet)
    end

    defp decode_endpoint_info(<<size :: [size(32),unsigned,integer], msg :: binary>> = data) when byte_size(msg) < size do
        {false, data}
    end
    defp decode_endpoint_info(<<size :: [size(32),unsigned,integer], msg :: binary>> = _data) when byte_size(msg) >= size do
        {true,<<>>}
    end
    defp decode_endpoint_info(data) do
        {false,data}
    end

    defp generate_random_data(size) do
        :crypto.rand_bytes(div(size, 8))
    end

end
