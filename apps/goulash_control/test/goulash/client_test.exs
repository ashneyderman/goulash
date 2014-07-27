defmodule Goulash.ClientTest.Acc do
    @behaviour Goulash.ClientBehaviour

    def prep(_state,_params) do
        {:ok, [:prep]}
    end
    
    def start(state) do
        {:ok, [:start|state]}
    end

    def pause(state) do
        {:ok, [:pause|state]}
    end
    
    def shutdown(state) do
        {:ok, [:shutdown|state]}
    end

    def on_event(state, event) do
        {:ok, [{:event, event} | state]}
    end

end

defmodule Goulash.ClientTest do
    use ExUnit.Case
    alias Goulash.Client, as: GClient
    alias Goulash.ClientBehaviour.Config, as: Config

    test "Check the normal state transitions" do
        {:ok, fsm} = :gen_fsm.start(GClient, 
                            %Config{client_module: Goulash.ClientTest.Acc,
                                           params: [test_param0: :test0,
                                                    test_param1: :test1]},
                            [])
        assert :initialized = GClient.state_name(fsm)
        assert :undefined = GClient.client_state(fsm)
        assert {:ok, :prepared} = GClient.prep(fsm)
        assert {:ok, :running} = GClient.start(fsm)
        assert {:ok, :paused} = GClient.pause(fsm)
        assert {:ok, :running} = GClient.resume(fsm)
        assert {:ok, [:shutdown,:start,:pause,:start,:prep]} = GClient.shutdown(fsm)
    end

    test "Check invalid state transitions" do
        {:ok, fsm} = :gen_fsm.start(GClient, 
                            %Config{client_module: Goulash.ClientTest.Acc,
                                           params: [test_param: :test]},
                            [])
        assert :initialized = GClient.state_name(fsm)
        assert :undefined = GClient.client_state(fsm)
        assert {:ok, :prepared} = GClient.prep(fsm)
        assert [:prep] = GClient.client_state(fsm)
        assert {:error, _} = GClient.pause(fsm)
        assert {:ok, [:shutdown, :prep]} = GClient.shutdown(fsm)

        {:ok, fsm} = :gen_fsm.start(GClient,
                            %Config{client_module: Goulash.ClientTest.Acc,
                                           params: [test_param: :test]}, 
                            [])
        assert :initialized = GClient.state_name(fsm)
        assert :undefined = GClient.client_state(fsm)
        assert {:ok, :prepared} = GClient.prep(fsm)
        assert :prepared = GClient.state_name(fsm)
        assert [:prep] = GClient.client_state(fsm)
        assert {:ok, :running} = GClient.start(fsm)
        assert {:error, _} = GClient.start(fsm)
        assert {:ok, :paused} = GClient.pause(fsm)
        assert {:error, _} = GClient.pause(fsm)
        assert {:ok, :running} = GClient.resume(fsm)
        assert {:error, _} = GClient.start(fsm)
        assert {:error, _} = GClient.resume(fsm)
        assert {:ok, [:shutdown,:start,:pause,:start,:prep]} = GClient.shutdown(fsm)
    end

    test "Check events" do
        {:ok, fsm} = :gen_fsm.start(GClient, 
                            %Config{client_module: Goulash.ClientTest.Acc,
                                           params: [test_param: :test]},
                            [])
        assert :initialized = GClient.state_name(fsm)
        assert {:ok, :prepared} = GClient.prep(fsm)
        assert {:ok, :running} = GClient.start(fsm)
        Process.send fsm, "test event", []
        assert [{:event,"test event"},:start,:prep] = GClient.client_state(fsm)
        assert {:ok, [:shutdown,{:event,"test event"},:start,:prep]} = GClient.shutdown(fsm)
    end

end