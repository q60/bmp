defimpl Inspect, for: BMP do
  defp bytes(binary) do
    size = byte_size(binary)

    cond do
      size == 0 ->
        "0 B"

      size > 24 ->
        result =
          for(<<chunk::binary-2 <- String.slice(Base.encode16(binary), 0..23)>>, do: chunk)
          |> Enum.map(&"\e[38;5;#{String.to_integer(&1, 16)}m\e[1m#{&1}\e[0m")
          |> Enum.join(" ")

        "#{result} ... \e[64G \e[93m|\e[0m \e[92m#{size}\e[0m"

      true ->
        result =
          for(<<chunk::binary-2 <- Base.encode16(binary)>>, do: chunk)
          |> Enum.map(&"\e[38;5;#{String.to_integer(&1, 16)}m\e[1m#{&1}\e[0m")
          |> Enum.join(" ")

        "#{result}\e[64G \e[93m|\e[0m \e[92m#{size}\e[0m"
    end
  end

  defp format(label, binary, display_value: true) do
    :io_lib.format("\e[95m\e[1m~-20.. s\e[0m\e[92m~-15.. s\e[0m \e[93m|\e[0m ~s", [
      "#{label}:",
      binary,
      bytes(binary)
    ])
  end

  defp format(label, binary, display_value: false) do
    :io_lib.format("\e[95m\e[1m~-35.. s\e[0m \e[93m|\e[0m ~s", [
      "#{label}",
      bytes(binary)
    ])
  end

  defp format(label, binary, unit) do
    with number <- :binary.decode_unsigned(binary, :little) do
      value =
        case unit do
          "byte" ->
            cond do
              number >= 1024 ** 2 ->
                "#{Float.round(number / 1024 ** 2, 2)} MiB"

              number >= 1024 ->
                "#{Float.round(number / 1024, 2)} KiB"

              true ->
                "#{number} B"
            end

          "number" ->
            "#{number}"

          "type" ->
            "type #{number}"

          _ ->
            "#{number} #{unit}"
        end

      :io_lib.format("\e[95m\e[1m~-20.. s\e[0m\e[92m~-15.. s\e[0m \e[93m|\e[0m ~s", [
        "#{label}:",
        value,
        bytes(binary)
      ])
    end
  end

  defp format(label, width, height, "size") do
    :io_lib.format("\e[95m\e[1m~-20.. s\e[0m\e[92m~-15.. s\e[0m \e[93m|\e[0m ~s", [
      "#{label}:",
      "#{:binary.decode_unsigned(width, :little)}x#{:binary.decode_unsigned(height, :little)}",
      bytes(width <> height)
    ])
  end

  def inspect(bmp, _opts) do
    show = """
    \e[91m\e[1mfile header:\e[0m
      #{format("signature", bmp.header.signature, display_value: true)}
      #{format("file size", bmp.header.file_size, "byte")}
      #{format("reserved", bmp.header.reserved, display_value: false)}
      #{format("data offset", bmp.header.data_offset, "byte")}

    \e[91m\e[1minfo header:\e[0m
      #{format("header size", bmp.info_header.info_header_size, "byte")}
      #{format("image size", bmp.info_header.width, bmp.info_header.height, "size")}
      #{format("planes", bmp.info_header.planes, "number")}
      #{format("color depth", bmp.info_header.color_depth, "bit")}
      #{format("compression", bmp.info_header.compression, "type")}
      #{format("compressed size", bmp.info_header.compressed_size, "byte")}
      #{format("x resolution", bmp.info_header.x_pixels_per_m, "px/m")}
      #{format("y resolution", bmp.info_header.y_pixels_per_m, "px/m")}
      #{format("used colors", bmp.info_header.used_colors, "number")}
      #{format("important colors", bmp.info_header.important_colors, "number")}

    #{:io_lib.format("\e[91m\e[1m~-22.. s\e[0m\e[92m~s\e[0m", ["color table:", bytes(bmp.color_table)])}

    #{:io_lib.format("\e[91m\e[1m~-22.. s\e[0m~s", ["raster data:", bytes(bmp.raster_data)])}
    """

    if file_name = bmp.name do
      """
      \e[92m\e[1m#{file_name}\e[0m
      \e[93m#{String.duplicate("-", String.length(bmp.name))}\e[0m
      """ <> show
    else
      show
    end
  end
end
