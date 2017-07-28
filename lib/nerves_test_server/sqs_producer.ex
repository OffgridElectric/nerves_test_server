defmodule NervesTestServer.SQSProducer do
  use GenStage
  require Logger

  def start_link(queue_name, opts \\ []) do
    GenStage.start_link(__MODULE__, queue_name, opts)
  end

  def init(queue_name) do
    state = %{
      demand: 0,
      queue: queue_name
    }

    {:producer, state, dispatcher: GenStage.BroadcastDispatcher}
  end

  def handle_demand(incoming_demand, %{demand: 0} = state) do
    new_demand = state.demand + incoming_demand

    Process.send(self(), :get_messages, [])

    {:noreply, [], %{state| demand: new_demand}}
  end
  def handle_demand(incoming_demand, state) do
    new_demand = state.demand + incoming_demand

    {:noreply, [], %{state| demand: new_demand}}
  end

  def handle_info(:get_messages, state) do
    aws_resp = ExAws.SQS.receive_message(
      state.queue,
      max_number_of_messages: min(state.demand, 10)
    )
    |> ExAws.request

    messages = case aws_resp do
      {:ok, resp} ->
        parse(resp.body.messages)
      {:error, reason} ->
        []
    end

    num_messages_received = Enum.count(messages)
    new_demand = max(state.demand - num_messages_received, 0)
    cond do
      new_demand == 0 -> :ok
      num_messages_received == 0 ->
        Process.send_after(self(), :get_messages, 200)
      true ->
        Process.send(self(), :get_messages, [])
    end

    {:noreply, messages, %{state| demand: new_demand}}
  end

  defp parse(messages) do
    Enum.map(messages, fn(message) ->
      body =
        message
        |> Map.get(:body)
        |> Poison.decode!

      record =
        body
        |> Map.get("Records")
        |> List.first

      key = get_in(record, ["s3", "object", "key"])
      etag = get_in(record, ["s3", "object", "etag"])

      Map.take(message, [:message_id, :receipt_handle])
      |> Map.put(:key, key)
      |> Map.put(:etag, etag)
    end)
  end
end