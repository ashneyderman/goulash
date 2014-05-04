defmodule Goulash.InstanceServer do
    use GenServer.Behaviour
    
    defrecord Config, 
              name: :undefined,
              mode: :undefined,
              init_params: [],
              status: :inactive,
              node: :undefined,
              clients_sup: :undefined

    def start_link(args) do
        :gen_server.start_link(__MODULE__, args, [])
    end

    @doc """
    Fetch state of the instance.
    """
    @spec info(instance :: pid()) :: Config.t
    def info(instance) do
        :gen_server.call(instance, :info)
    end

    @doc """
    Start instance as a slave. Using slave module of erlang.
    """
    @spec start_slave(instance :: pid()) :: :ok | {:error, term()}
    def start_slave(instance) when is_pid(instance) do
        :gen_server.call(instance, :start_slave)
    end

    @doc """
    Start instance in the same VM. This is useful for testing.
    """
    @spec start_in_vm(instance :: pid()) :: :ok | {:error, term()}
    def start_in_vm(instance) when is_pid(instance) do
        :gen_server.call(instance, :start_in_vm)
    end

    def stop(instance) when is_pid(instance) do
        :gen_server.call(instance, :stop)
    end

    @doc """
    TODO - method docs
    """
    @spec prep_client(instance :: pid(),
                        config :: Goulash.ClientBehavior.ClientConfig.t) :: 
            {:ok, Goulash.ClientBehavior.client_ref} | 
            {:error, term()}
    def prep_client(instance, config) do
        {:ok, [result] } = prep_clients(instance,config,1)
        {:ok, result}
    end

    @doc """
    TODO - method docs
    """
    @spec prep_clients(instance :: pid(),
                         config :: Goulash.ClientBehavior.ClientConfig.t,
                         number :: pos_integer()) :: 
            {:ok, list(Goulash.ClientBehavior.client_ref)} | 
            {:error, term()}
    def prep_clients(instance, config, number) do
        :gen_server.call(instance, {:prep_clients, config, number})
    end

    @spec start_clients(instance :: pid) ::
        :ok |
        {:error, term()}
    def start_clients(instance) do
        :gen_server.call(instance, :start_clients)
    end


    @doc """
    TODO - This works only for in_vm, needs a thought when dealing with remote clients
    """
    @spec all_clients(instance :: pid()) ::
            list(Goulash.ClientBehavior.client_ref)
    def all_clients(instance) do
        :gen_server.call(instance, :all_clients)
    end
    
    ## gen_server callbacks
    def init(Config[] = args) do
        {:ok, args}
    end

    def handle_call({:send_app, _app}, _from, state) do
        {:reply, :ok, state}
    end

    def handle_call(:info, _from, state) do
        {:reply, state, state}
    end
    
    # start handlers
    def handle_call(:start_in_vm, _from, state) do
        {:reply, :ok, state.status(:active)
                           .mode(:in_vm)
                           .node(node())}
    end
    def handle_call(:start_slave, _from, state) do
        host = to_char_list(state.init_params[:hostname])
        instance = to_char_list(state.name)
        args = to_char_list("-setcookie #{Node.get_cookie}")
        case :slave.start_link(host,instance,args) do
            {:ok, node} ->
                {:reply, :ok, state.status(:active)
                                   .mode(:slave)
                                   .node(node)}
            {:error, error} ->
                {:reply, {:error, error}, state.status(:error)
                                               .mode(:undefined)                                                           
                                               .node(:undefined)}
        end
    end

    ## prep hnadlers
    def handle_call({:prep_clients, config, number}, 
                    _from, 
                    Config[mode: :in_vm] = state) do
        {:ok, clients_sup} = case state.clients_sup do
            :undefined -> Goulash.ClientSup.start_link(config)                
            _ -> {:ok, state.clients_sup}
        end
        new_clients = Enum.map(1..number, 
                                fn(_) -> 
                                    {:ok, new_client} = :supervisor.start_child(clients_sup, [config.params]) 
                                    new_client
                                end)
        {:reply, {:ok, new_clients}, state.clients_sup(clients_sup)}
    end
    def handle_call({:prep_clients, _config, _number}, 
                    _from, 
                    Config[mode: :slave] = state) do
        # FIXME - implement
        {:reply, {:error, :not_implemented_yet}, state}
    end

    # start_clients 
    def handle_call(:start_clients, 
                    _from, 
                    Config[clients_sup: clients_sup] = state) do
        :supervisor.which_children(clients_sup)
        |> Enum.map(&(elem(&1,1)))
        {:reply, :ok, state}
    end

    # all_clients handlers
    def handle_call(:all_clients, 
                    _from, 
                    Config[clients_sup: :undefined] = state) do
        {:reply, [], state}
    end
    def handle_call(:all_clients, _from, Config[mode: :in_vm] = state) do
        result = :supervisor.which_children(state.clients_sup) 
                 |> Enum.map(&(elem(&1,1)))
        {:reply, result, state}
    end
    def handle_call(:all_clients, 
                    _from, 
                    Config[mode: :slave] = state) do
        # FIXME - implement
        {:reply, {:error, :not_implemented_yet}, state}
    end

    # stop handlers
    # def handle_call({:start_app, app_name}, _from, state) do
    #     result = :rpc.call(state.node, :application, :start, [app_name])
    #     {:reply, result, state}
    # end
    
    def handle_call(:stop, _from, state = Config[mode: :slave]) do
        :ok = :slave.stop(state.node)
        {:reply, :ok, state.mode(:undefined)
                           .status(:inactive)}
    end

    def handle_call(:stop, _from, state = Config[mode: :in_vm]) do

        {:reply, :ok, state.mode(:undefined)
                           .status(:inactive)}
    end


    def handle_call(request, from, state) do
        super(request, from, state)
    end

end