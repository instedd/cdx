defmodule Cgi do
  def escape(str) when is_binary(str) do
    :http_uri.encode(:binary.bin_to_list(str))
  end
end
