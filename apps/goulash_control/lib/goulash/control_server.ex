defmodule Goulash.ControlServer do
    use GenServer.Behaviour

    @regname Goulash.ControlServer

    defrecord LoadConfig,   
              name: "", 
              description: "",
              total_instances: 0,
              instances: []

    defrecord State, load_configs: []

    # APIs
    def start_link() do
        :gen_server.start_link( {:local, @regname}, __MODULE__, :ok, [] )
    end

    def add_config(load_config) do
        :gen_server.cast( @regname, { :add_config, load_config })
    end

    def show_configs() do
        :gen_server.call( @regname, :show_configs )
    end    

    def stop() do
        :gen_server.cast( @regname, :stop )
    end

    # callbacks
    def init(:ok) do
        { :ok, State.new }
    end

    def handle_call( :show_configs, _from, state ) do
        { :reply, state.load_configs, state }
    end
    def handle_call(request, from, state) do
        super(request, from, state)
    end

    def handle_cast({ :add_config, load_config }, state) do
        { :noreply, state.update_load_configs &[load_config|&1] }
    end
    def handle_cast( :stop, state) do
        { :stop, :normal, state }
    end
    def handle_cast(request, state) do
        super(request, state)
    end

end
