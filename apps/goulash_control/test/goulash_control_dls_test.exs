defmodule GoulashControlTest do
    #use Goulash.ControlDsl 

    # clients_load "15 servers load config" do
    #     spawn 15 g%"instances" do
    #         instance 1,
    #             weight: 10 g%"percent",
    #             name_pattern: g%"head_instance",
    #             type: :ec2,
    #             init_parameters: [ :from_reserverd_pool ]

    #         instances 2..5, 
    #             weight: 20 g%"percent"
    #             name_pattern: g%"smallish_instance_{}"

    #         instances 6..15,
    #             weight: 70 g%"percent"
    #             name_pattern: g%"biggish_instance_{}"
    #     end
    # end

    # client_servers "15 client servers config" do
        
    # end

    # test "the truth" do
    #     IO.puts "Running the tests"
    #     myif (4 + 5 > 8) do
    #         IO.puts "4 + 5 > 8 is true"
    #     else
    #         IO.puts "4 + 3 > 8 is false"
    #     end
    # end

    # laodtest "", run_for: 15m do
    #     spawn 



end
