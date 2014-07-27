defmodule Goulash.Client do
    @behaviour :gen_fsm

    defmodule State do
        defstruct client_config: :undefined,
                   client_state: :undefined    
    end

    alias Goulash.ClientBehaviour.Config, as: Config

    ## API routines
    def start_link(config) do
        :gen_fsm.start_link(__MODULE__,config,[])
    end

    def state_name(fsm) do
        :gen_fsm.sync_send_all_state_event(fsm, :state_name)
    end

    def client_state(fsm) do
        :gen_fsm.sync_send_all_state_event(fsm, :client_state)
    end
    
    def prep(fsm) do
        :gen_fsm.sync_send_event(fsm, :prepare)
    end

    def start(fsm) do
        :gen_fsm.sync_send_event(fsm, :start)
    end
    
    def resume(fsm) do
        :gen_fsm.sync_send_event(fsm, :resume)
    end

    def pause(fsm) do
        :gen_fsm.sync_send_event(fsm, :pause)
    end 

    def shutdown(fsm) do
        :gen_fsm.sync_send_event(fsm, :shutdown)
    end

    @doc false
    @spec init(config :: Config.t) ::
        {:ok, state_name :: atom(), state :: State.t} |
        {:stop, reason :: term()}
    def init(%Config{}=config) do
        # TODO: verify that client behaviour is exposed
        case Code.ensure_loaded(config.client_module) do
            {:error, _error} ->
                # TODO log error here
                {:stop, "Unable to load client module #{config.client_module}"}
            {:module, _module} ->
                {:ok, :initialized, %State{client_config: config}}
        end
    end

    @doc false
    def handle_event(event, state_name, state_data) do 
        { :stop, {:bad_event, state_name, event}, state_data }
    end

    @doc false
    def handle_sync_event(:state_name, _from, state_name, state_data) do
        {:reply, state_name, state_name, state_data}
    end
    def handle_sync_event(:client_state, _from, state_name, state_data) do
        {:reply, state_data.client_state, state_name, state_data}
    end
    def handle_sync_event(event, _from, state_name, state_data) do
        { :stop, {:bad_sync_event, state_name, event}, state_data }
    end

    @doc false
    def handle_info(event, state_name, state) do
        case do_call(:on_event, [event], state) do
            {:ok, new_client_state} ->
                {:next_state, 
                 state_name, 
                 %State{state | 
                        client_state: new_client_state}}
            {:error, reason} ->
                {:stop, reason, state}
        end
    end

    @doc false
    def terminate(_reason, _state_name, _state_data) do
        :ok
    end

    @doc false
    def code_change(_old, state_name, state_data, _extra) do
        { :ok, state_name, state_data }
    end

    ## FSM states
    def initialized(:prepare, _from, %State{} = state) do
        case do_call(:prep, [state.client_config.params], state) do
            {:ok, new_client_state} ->
                {:reply, 
                    {:ok, :prepared}, 
                    :prepared, 
                    %State{state | client_state: new_client_state}}
            {:error, reason} ->
                {:stop,
                    reason,
                    {:error, {"Unable to prepare the client", reason}},
                    state}
        end
    end

    def prepared(:start, _from, %State{} = state) do
        case do_call(:start, state) do
            {:ok, new_client_state} ->
                {:reply, 
                    {:ok, :running}, 
                    :running, 
                    %State{state | client_state: new_client_state}}
            {:error, reason} ->
                {:stop, 
                    reason, 
                    {:error, {"Unable to start the client", reason}}, 
                    state}
        end
    end
    def prepared(:shutdown, _from, %State{} = state) do
        do_shutdown(state)
    end
    def prepared(msg, _from, %State{} = state) do
        {:reply, 
            {:error, {"Message can not be processed while in state prepared",msg}}, 
            :prepared, 
            state}
    end

    def running(:pause, _from, %State{} = state) do
        case do_call(:pause, state) do
            {:ok, new_client_state} ->
                {:reply, 
                    {:ok, :paused},
                    :paused, 
                    %State{state | client_state: new_client_state}}
            {:error, reason} ->
                {:stop, 
                    reason, 
                    {:error, {"Unable to pause the client", reason}},
                    state}
        end
    end
    def running(:shutdown, _from, %State{} = state) do
        do_shutdown(state)
    end
    def running(msg, _from, %State{} = state) do
        {:reply, 
            {:error, {"Message can not be processed while in state running",msg}}, 
            :running, 
            state}
    end

    
    def paused(:resume, _from, %State{} = state) do
        case do_call(:start,state) do
            {:ok, new_client_state} ->
                {:reply,
                    {:ok, :running},
                    :running, 
                    %State{state | client_state: new_client_state}}
            {:error, reason} ->
                {:stop, 
                    :shutdown,
                    {:error, {"Unable to shutdown the client normally", reason}},
                    state}
        end
    end
    def paused(:shutdown, _from, %State{} = state) do
        do_call(:shutdown,state)
    end
    def paused(msg, _from, %State{} = state) do
        {:reply, 
            {:error, {"Message can not be processed while in state paused",msg}}, 
            :paused, 
            state}
    end

    ## private routines
    defp do_shutdown(state) do
        case do_call(:shutdown,state) do
            {:ok, new_client_state} ->
                {:stop, 
                    :normal,
                    {:ok, new_client_state}, 
                    %State{state | client_state: new_client_state}}
            {:error, reason} ->
                {:stop, 
                    :shutdown,
                    {:error, {"Unable to shutdown the client normally", reason}},
                    state}
        end
    end

    defp do_call(method, state) do
        do_call(method,[],state)
    end

    defp do_call(method, args, state) do
        module = fetch_module(state)
        apply(module, method, [state.client_state|args])
    end

    defp fetch_module(%State{}=state) do
        fetch_module(state.client_config)
    end
    defp fetch_module(%Config{}=config) do
        config.client_module
    end

    # defp on_event(event, state) do
    #     module = fetch_module(state)
    #     apply(module, :on_event, [state.client_state, event])
    # end

end