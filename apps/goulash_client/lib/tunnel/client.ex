defmodule Tunnel.Client do
    @behaviour Goulash.ClientBehavior
    @send_timeout 15000
    @connect_timeout 10000
    @send_interval 1000

    use GenServer.Behaviour

    defrecord Config,
        verbose: :quite,
        hostname: :undefined,
        port: :undefined,
        rate: :undefined,
        session_id: :undefined,
        socket: :undefined,
        timer_ref: :undefined,
        ep_info_received: false,
        ep_info_buffer: <<>>

    def prep(args) do
        :gen_server.start_link(__MODULE__, args, [])
    end

    def start(client) do
        :gen_server.call(client, :start)
    end

    def stop(client) do
        :gen_server.call(client, :stop)
    end

    def shutdown(client) do
        :gen_server.call(client, :shutdown)
    end

    def init(options) do
        {:ok, Config.new(options)}
    end

    def handle_call(:start, _from, state) do
        # IO.puts "hostname: #{state.hostname}; port: #{state.port}"
        # IO.inspect state
        case :gen_tcp.connect(to_char_list(state.hostname), state.port, [active: false,
                                                           mode: :binary,
                                                           packet: :raw,
                                                           delay_send: false,
                                                           send_timeout: @send_timeout,
                                                           send_timeout_close: false], @connect_timeout) do
            {:ok, socket} ->
                :ok = start_tunnel(state.socket(socket))
                :inet.setopts(socket, [{:active, :once}])
                tref = Process.send_after(Process.self(), {:send_next_chunk, state.rate}, @send_interval)
                {:reply, :ok, state.socket(socket)
                                   .timer_ref(tref)}
            {:error, reason} ->
                {:stop, reason, state}
        end
    end

    def handle_call(:stop, _from, Config[timer_ref: tref] = state) do
        IO.puts "stop call"
        :timer.cancel(tref)
        {:reply, :ok, state}
    end

    def handle_call(:shutdown, _from, state) do
        IO.puts "shutdown call"
        try do
            :gen_tcp.close(state.socket)
        catch
            _, _ -> 
                :ok
        end
        {:stop, :shutdown, state}
    end

    def handle_call(request, from, state) do
        IO.puts "Unhandles call:"
        IO.inspect request
        super(request, from, state)
    end

    def handle_info({:tcp, socket, data}, Config[ep_info_received: false, ep_info_buffer: buffer] = state) do
       msg = <<buffer :: binary, data :: binary>> 
       {new_ep_info_received, new_ep_info_buffer} = decode_endpoint_info(msg)
       :inet.setopts(socket, [{:active, :once}])
       {:noreply, state.ep_info_received(new_ep_info_received)
                       .ep_info_buffer(new_ep_info_buffer)}
    end

    def handle_info({:tcp, socket, _}, Config[ep_info_received: true] = state) do
        :inet.setopts(socket, [{:active, :once}])
        {:noreply, state}
    end

    def handle_info({:tcp_closed, _socket}, Config[timer_ref: tref] = state) do
        :timer.cancel(tref)
        {:stop, :normal, state.timer_ref(:undefined)}
    end
    
    def handle_info({:send_next_chunk, _}, Config[ep_info_received: false] = state) do
        tref = Process.send_after(Process.self(), {:send_next_chunk, state.rate}, @send_interval)
        {:noreply, state.timer_ref(tref)}
    end
    
    def handle_info({:send_next_chunk, _}, Config[] = state) do
        tpr = div(1000, @send_interval)
        next_chunk_size = div(state.rate, tpr)
        data_chunk = generate_random_data(next_chunk_size)
        case :gen_tcp.send(state.socket, data_chunk) do
            :ok -> 
                tref = Process.send_after(Process.self(), {:send_next_chunk, state.rate}, @send_interval) 
                {:noreply, state.timer_ref(tref)}
            {:error, reason} ->
                IO.puts "Error sending data for session #{state.session_id}. Error: #{reason}"
                {:stop, reason, state}
        end
    end

    def handle_info(request, state) do
        IO.puts "Unhandled info:"
        IO.inspect request
        super(request, state)
    end

    # private helpers
    defp start_tunnel(Config[] = state) do
        {:ok, msg} = :xmlrpc_encode.payload({:call, :start_tunnel, [{:struct, [
                                                                    {:id,state.session_id},
                                                                    {:"listen.endpoint", 'localhost:20000'}
                                                                    ]
                                                                 }]})
        binmsg = iolist_to_binary(msg)
        msgsize = byte_size(binmsg)
        packet = <<msgsize :: [size(32), integer], 1 :: [size(32), integer], 1 :: [size(32), integer], binmsg :: binary>>
        :gen_tcp.send(state.socket,packet)
    end

    defp decode_endpoint_info(<<size :: [size(32),unsigned,integer], msg :: binary>> = data) when byte_size(msg) < size do
        {false, data}
    end
    defp decode_endpoint_info(<<size :: [size(32),unsigned,integer], msg :: binary>> = _data) when byte_size(msg) >= size do
        # we do not care about the content so we are ignoring the data.
        {true,<<>>}
    end
    defp decode_endpoint_info(data) do
        {false,data}
    end

    defp generate_random_data(size) do
        :crypto.rand_bytes(div(size, 8))
    end

end
