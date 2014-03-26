defmodule Cdp.DateTime do
  def now do
    Ecto.DateTime.from_erl(:calendar.universal_time())
  end
end
