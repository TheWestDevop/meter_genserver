defmodule MetexGenserver.Worker do
    use GenServer

    ## Client API
    def start_link(init_args \\ []) do
        # you may want to register your server with `name: __MODULE__`
        # as a third argument to `start_link`
        GenServer.start_link(__MODULE__, [init_args])
    end

    def stop(pid) do
        GenServer.cast(pid,:stop)
    end

    def reset_state(pid) do
        GenServer.cast(pid,:reset_state)
    end

    def get_state(pid) do
        GenServer.call(pid,:get_state)
    end

    def get_temperature(pid,location) do
        GenServer.call(pid,{:location, location})
    end

    ## Server API
    
    @impl true
    def init(_args) do
        {:ok, %{}}
    end
     
    @impl true
    def handle_call({:location,location},_from,state) do
        case temperature_of(location) do
           {:ok,temp} -> 
             new_state = update_state(state,location)
             {:reply,"#{temp}°C",new_state}

           _ -> {:reply, :error, state}
            
        end
    end

    @impl true
    def handle_call(:get_state, _payload, state) do
        {:reply, state, state}
    end

    @impl true
    def handle_cast(:reset_state, _state) do
        {:noreply,%{}}
    end

    @impl true
    def handle_cast(:stop, state) do
        {:stop,:normal,state}
    end

    @impl true
    def terminate(reason, state) do
        # We could write to a file, database etc
        IO.puts "server terminated because of #{inspect reason}"
           inspect state 
        :ok
    end

    
    
     # Helper Function  


    defp temperature_of(location) do
        url_for(location) |> HTTPoison.get() |> parse_response
      end
    
      defp url_for(location) do
        location = URI.encode(location)
        "http://api.openweathermap.org/data/2.5/weather?q=#{location}&appid=#{apikey()}"
      end
    
      defp parse_response(
             {:ok,
              %HTTPoison.Response{
                body: body,
                status_code: 200
              }}
           ) do
        body |> JSON.decode() |> compute_temperature
      end
    
      defp parse_response(_) do
        :error
      end
    
      defp compute_temperature({:ok, x}) do
        try do
          temp = (x["main"]["temp"] - 273.15) |> Float.round(1)
          {:ok, temp}
        rescue
          _ -> :error
        end
      end
    
      defp apikey do
        "your openweathermap api key here "
      end

      defp update_state(old_state,location) do
         case Map.has_key?(old_state,location) do
           true -> Map.update!(old_state,location, &(&1 + 1))
           false -> Map.put_new(old_state,location,1)
         end
          
      end
end
