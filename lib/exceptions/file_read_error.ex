defmodule Exceptions.FileReadError do
  defexception [:message, :path]

  def message(%{message: message, path: path}) do
    "error reading file \"#{path}\": #{message}"
  end
end
