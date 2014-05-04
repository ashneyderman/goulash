defmodule Goulash.ControlDsl do

    @moduledoc """
    """
    defmacro __using__(opts) do
        IO.inspect opts
        quote do
            import unquote(__MODULE__)
        end
    end

    @doc """
    The following declaration should be possible with the set of macros in this 
    module:
    """
    defmacro with(number, type, instance_specs) do
        quote do
            n = unquote(number)
            t = unquote(type)
            s = unquote(instance_specs)
            IO.puts "Number: #{n}"
            IO.puts "Type: #{t}"
            IO.puts "Instance Specs: #{s}"
        end
    end

    defmacro myif(condition, clauses) do
        prolog = quote do: (IO.puts("prolog"))
        do_clause = Keyword.get(clauses, :do, nil) 
        else_clause = Keyword.get(clauses, :else, nil)
        result = quote do 
            unquote(prolog)
            case unquote(condition) do
                true -> unquote(do_clause)
                _ -> unquote(else_clause)
            end
        end
        IO.inspect result
        result
    end

    

end