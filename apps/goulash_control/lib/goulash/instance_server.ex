defmodule Goulash.InstanceServer do
    @doc """
    Instance server - a module that is a container for all the clients that 
    belong in the instance scope.

    For example, one test might have 20 instances and each of the instances 
    might be responsible for 1K clients. This would be the test that hits a 
    service with 20K clients.

    Each of the instances might be local within the same VM or remote on a 
    separate server/VM.

    Stopping an instance will cause all of its clients to shutdown.
    """
    use GenServer

    defmodule Config do
        defstruct name: :undefined,
           init_params: []
    end

    defmodule State do
        @derive Access
        defstruct name: :undefined,
                  mode: :undefined,
                status: :inactive,
                  node: :undefined,
           init_params: [],
           clients_sup: :undefined
    end

    alias Goulash.ClientBehaviour.Config, as: ClientConfig
    alias Goulash.Client, as: GClient
    
    ## -------------------------------------------------------------------------
    ## API functions
    ## -------------------------------------------------------------------------

    def start_link(%Config{} = args) do
        :gen_server.start_link(__MODULE__, args, [])
    end

    @doc """
    Fetch state of the instance.
    """
    @spec info(instance :: pid()) :: State.t
    def info(instance) do
        :gen_server.call(instance, :info)
    end

    @doc """
    Start instance in the same VM. Keep in mind this might not work as well as 
    starting multiple VMs, due to network constraints.
    """
    @spec start_in_vm(instance :: pid()) :: :ok | {:error, term()}
    def start_in_vm(instance) when is_pid(instance) do
        :gen_server.call(instance, :start_in_vm)
    end

    @doc """
    Start the instance as a slave. Using slave module of erlang.
    """
    @spec start_slave(instance :: pid()) :: :ok | {:error, term()}
    def start_slave(instance) when is_pid(instance) do
        :gen_server.call(instance, :start_slave)
    end
    
    def stop(instance) when is_pid(instance) do
        :gen_server.call(instance, :stop)
    end

    @doc """
    Create specified number of instances of goulash clients and calls prep 
    lifecycle callback on them - one at a time.
    """
    @spec prep_clients(instance :: pid(),
                         config :: ClientConfig.t,
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
    TODO - This works only for in_vm, needs a thought when dealing with remote 
    clients
    """
    @spec all_clients(instance :: pid()) ::
            list(Goulash.ClientBehavior.client_ref)
    def all_clients(instance) do
        :gen_server.call(instance, :all_clients)
    end
    
    ## -------------------------------------------------------------------------
    ## gen_server callbacks
    ## -------------------------------------------------------------------------

    def init(%Config{} = config) do
        {:ok, clients_sup} = Goulash.ClientSup.start_link()
        {:ok, %State{name: config.name,
                     init_params: config.init_params,
                     clients_sup: clients_sup}}
    end

    def handle_call({:send_app, _app}, _from, state) do
        {:reply, :ok, state}
    end

    def handle_call(:info, _from, state) do
        {:reply, state, state}
    end
    
    # start handlers
    def handle_call(:start_in_vm, _from, state) do
        {:reply, :ok, %State{state | status: :active,
                                       mode: :in_vm,
                                       node: node()}}
    end
    def handle_call(:start_slave, _from, state) do
        host = to_char_list(state.init_params[:hostname])
        instance = to_char_list(state.name)
        args = to_char_list("-setcookie #{Node.get_cookie}")
        case :slave.start_link(host,instance,args) do
            {:ok, node} ->
                {:reply, :ok, 
                         %State{state | status: :active,
                                          mode: :slave,
                                          node: node}}
            {:error, error} ->
                {:reply, {:error, error}, 
                         %State{state | status: :error,
                                          mode: :undefined,
                                          node: :undefined}}
        end
    end

    ## prep hnadlers
    def handle_call({:prep_clients, %ClientConfig{}=config, number}, 
                    _from, 
                    %State{mode: :in_vm} = state) do
        new_clients = Enum.map(1..number, 
            fn(_) -> 
                {:ok, new_client} = Goulash.ClientSup.init_client(
                                        state.clients_sup, 
                                        config)
                {:ok, :prepared} = GClient.prep(new_client)
                new_client
            end)
        {:reply, {:ok, new_clients}, state}
    end
    def handle_call({:prep_clients, %ClientConfig{}=_config, _number}, 
                    _from, 
                    %State{mode: :slave} = state) do
        # FIXME - implement
        {:reply, {:error, :not_implemented_yet}, state}
    end

    # start_clients 
    def handle_call(:start_clients, 
                    _from, 
                    %State{} = state) do
        :supervisor.which_children(state.clients_sup)
        |> Enum.map(&(elem(&1,1)))
        |> Enum.each(
            fn(client) ->
                GClient.start(client)
            end)
        {:reply, :ok, state}
    end

    # all_clients handlers
    def handle_call(:all_clients, 
                    _from, 
                    %State{clients_sup: :undefined} = state) do
        {:reply, [], state}
    end
    def handle_call(:all_clients, 
                    _from, 
                    %State{mode: :in_vm} = state) do
        result = :supervisor.which_children(state.clients_sup) 
                 |> Enum.map(&(elem(&1,1)))
        {:reply, result, state}
    end
    def handle_call(:all_clients, 
                    _from, 
                    %State{mode: :slave} = state) do
        # FIXME - implement
        {:reply, {:error, :not_implemented_yet}, state}
    end

    def handle_call(:stop, _from, %State{mode: :in_vm} = state) do
        :supervisor.which_children(state.clients_sup) 
            |> Enum.map(&(elem(&1,1)))
            |> Enum.each(
                fn(client) ->
                    Goulash.Client.shutdown(client)    
                end)
        {:reply, :ok, %State{state | mode: :undefined,
                                     status: :inactive}}
    end
    def handle_call(:stop, _from, %State{mode: :slave} = state) do
        :ok = :slave.stop(state.node)
        {:reply, :ok, %State{state | mode: :undefined,
                                     status: :inactive}}
    end

    def handle_call(request, from, state) do
        super(request, from, state)
    end

end

    #
    # @doc """
    # Creates an instance of goulash client and calls prep lifecycle callback on 
    # it.
    # """
    # @spec prep_client(instance :: pid(),
    #                     config :: Goulash.ClientBehavior.ClientConfig.t) :: 
    #         {:ok, Goulash.ClientBehavior.client_ref} | 
    #         {:error, term()}
    # def prep_client(instance, config) do
    #     {:ok, [result] } = prep_clients(instance,config,1)
    #     {:ok, result}
    # end
    #

    # @doc """
    # Start the instance as a slave. Using slave module of erlang.
    # """
    # @spec start_slave(instance :: pid()) :: :ok | {:error, term()}
    # def start_slave(instance) when is_pid(instance) do
    #     :gen_server.call(instance, :start_slave)
    # end

    # def handle_call(:start_slave, _from, state) do
    #     host = to_char_list(state.init_params[:hostname])
    #     instance = to_char_list(state.name)
    #     args = to_char_list("-setcookie #{Node.get_cookie}")
    #     case :slave.start_link(host,instance,args) do
    #         {:ok, node} ->
    #             {:reply, :ok, state.status(:active)
    #                                .mode(:slave)
    #                                .node(node)}
    #         {:error, error} ->
    #             {:reply, {:error, error}, state.status(:error)
    #                                            .mode(:undefined)                                                           
    #                                            .node(:undefined)}
    #     end
    # end
    #
    # def handle_call(:all_clients, 
    #                 _from, 
    #                 Config[mode: :slave] = state) do
    #     # FIXME - implement
    #     {:reply, {:error, :not_implemented_yet}, state}
    # end
    # def handle_call(:stop, _from, state = Config[mode: :slave]) do
    #     :ok = :slave.stop(state.node)
    #     {:reply, :ok, state.mode(:undefined)
    #                        .status(:inactive)}
    # end
