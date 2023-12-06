defmodule BMP do
  alias BMP.{BMPHeader, DIBHeader}

  @moduledoc """
  Elixir library implementing `BMP` struct allowing to interact with bitmap images.

  This library adds new type called `t:bmp/0` and several functions to work with BMP files.

  ## Examples

      iex(1)> img = BMP.new({1920, 1080}, 24, "#F5ABB9")
      BMP header:
        signature:          BM              | 42 4D                   | 2
        file size:          5.93 MiB        | 36 EC 5E 00             | 4
        reserved                            | 00 00 00 00             | 4
        data offset:        54 B            | 36 00 00 00             | 4

      DIB header:
        header size:        40 B            | 28 00 00 00             | 4
        image size:         1920x1080       | 80 07 00 00 38 04 00 00 | 8
        planes:             1               | 01 00                   | 2
        color depth:        24 bit          | 18 00                   | 2
        compression:        type 0          | 00 00 00 00             | 4
        compressed size:    5.93 MiB        | 00 EC 5E 00             | 4
        x resolution:       255 px/m        | FF 00 00 00             | 4
        y resolution:       255 px/m        | FF 00 00 00             | 4
        used colors:        0               | 00 00 00 00             | 4
        important colors:   0               | 00 00 00 00             | 4

      color table:          0 B

      raster data:          B9 AB F5 B9 AB F5 B9 AB F5 B9 AB F5 ...   | 6220800

      iex(2)> BMP.write_file!(img, "cat.bmp")
      :ok

      iex(3)> BMP.read_file!("cat.bmp") == img
      true
  """

  defstruct bmp_header: %BMPHeader{},
            dib_header: %DIBHeader{},
            color_table: <<>>,
            raster_data: <<>>,
            name: nil

  @typedoc """
  Bitmap image type.
  """
  @type bmp :: %BMP{}
  @typedoc """
  Color depth in bits.
  """
  @type color_depth :: 1 | 4 | 8 | 16 | 24
  @typedoc false
  @type bi_rgb :: 0
  @typedoc false
  @type bi_rle8 :: 1
  @typedoc false
  @type bi_rle4 :: 2
  @typedoc """
  BMP compression type.

  * BI_RGB - no compression
  * BI_RLE8 - 8 bit RLE encoding
  * BI_RLE4 - 4 bit RLE encoding
  """
  @type compression :: bi_rgb() | bi_rle8() | bi_rle4()

  defp num_to_bytes(n, size) do
    bytes = :binary.encode_unsigned(n, :little)
    current_size = byte_size(bytes)

    cond do
      current_size < size ->
        bytes <> :binary.copy(<<0x00>>, size - current_size)

      true ->
        bytes
    end
  end

  @doc """
  Creates new BMP image filled with specified color.

  Takes width and height, color depth and fill color - either hex string or `<<r, g, b>>` binary, returns a `t:bmp/0`.

  ## Examples

      iex(1)> BMP.new {1600, 900}, 24, "#F5ABB9"
      BMP header:
        signature:          BM              | 42 4D                   | 2
        file size:          4.12 MiB        | 36 EB 41 00             | 4
        reserved                            | 00 00 00 00             | 4
        data offset:        54 B            | 36 00 00 00             | 4

      DIB header:
        header size:        40 B            | 28 00 00 00             | 4
        image size:         1600x900        | 40 06 00 00 84 03 00 00 | 8
        planes:             1               | 01 00                   | 2
        color depth:        24 bit          | 18 00                   | 2
        compression:        type 0          | 00 00 00 00             | 4
        compressed size:    4.12 MiB        | 00 EB 41 00             | 4
        x resolution:       255 px/m        | FF 00 00 00             | 4
        y resolution:       255 px/m        | FF 00 00 00             | 4
        used colors:        0               | 00 00 00 00             | 4
        important colors:   0               | 00 00 00 00             | 4

      color table:          0 B

      raster data:          B9 AB F5 B9 AB F5 B9 AB F5 B9 AB F5 ...   | 4320000

      iex(2)> BMP.new({1600, 900}, 24, "#F5ABB9") == BMP.new({1600, 900}, 24, <<245, 171, 185>>)
      true
  """
  @spec new({non_neg_integer(), non_neg_integer()}, color_depth(), String.t()) :: bmp()
  def new(size, depth, _fill = <<?\#, r::16, g::16, b::16>>) do
    pixel_color =
      [<<r::16>>, <<g::16>>, <<b::16>>]
      |> Enum.map(&String.to_integer(&1, 16))
      |> :binary.list_to_bin()

    new(size, depth, pixel_color)
  end

  def new({width, height}, depth, _fill = <<r::8, g::8, b::8>>) do
    row_size = ceil(depth * width / 32) * 4
    size = row_size * height + 54
    padding = row_size - width * div(depth, 8)

    %BMP{
      bmp_header: %BMPHeader{
        file_size: num_to_bytes(size, 4)
      },
      dib_header: %DIBHeader{
        width: num_to_bytes(width, 4),
        height: num_to_bytes(height, 4),
        color_depth: num_to_bytes(depth, 2),
        compressed_size: num_to_bytes(size - 54, 4)
      },
      raster_data:
        Enum.map(1..height, fn _ ->
          :binary.copy(<<b, g, r>>, width) <> <<0::size(8 * padding)>>
        end)
        |> :binary.list_to_bin()
    }
  end

  @doc """
  Reads specified file to `t:bmp/0`.

  Takes path to file as its only argument and returns `t:bmp/0` on success, raises `Exceptions.FileReadError` otherwise.

  ## Examples

      iex(1)> BMP.read_file("mew.bmp")
      mew.bmp
      -------
      BMP header:
        signature:          BM              | 42 4D                   | 2
        file size:          3.05 KiB        | 36 0C 00 00             | 4
        reserved                            | 00 00 00 00             | 4
        data offset:        54 B            | 36 00 00 00             | 4

      DIB header:
        header size:        40 B            | 28 00 00 00             | 4
        image size:         32x32           | 20 00 00 00 20 00 00 00 | 8
        planes:             1               | 01 00                   | 2
        color depth:        24 bit          | 18 00                   | 2
        compression:        type 0          | 00 00 00 00             | 4
        compressed size:    3.0 KiB         | 00 0C 00 00             | 4
        x resolution:       3780 px/m       | C4 0E 00 00             | 4
        y resolution:       3780 px/m       | C4 0E 00 00             | 4
        used colors:        0               | 00 00 00 00             | 4
        important colors:   0               | 00 00 00 00             | 4

      color table:          0 B

      raster data:          FF FF FF FF FF FF FF FF FF FF FF FF ...   | 3072

      iex(2)> BMP.read_file("xeon.jpg")
      ** (Exceptions.FileReadError) error reading file "xeon.jpg": not a BMP file
          (bmp 0.1.0) lib/bmp.ex:101: BMP.read_file!/1
          iex:2: (file)
  """
  @spec read_file!(Path.t()) :: bmp()
  def read_file!(path) do
    case read_file(path) do
      {:ok, bmp} ->
        bmp

      {:error, :not_a_bmp} ->
        raise Exceptions.FileReadError, message: "not a BMP file", path: path
    end
  end

  @doc """
  Reads specified file to `t:bmp/0`.

  Takes path to file as its only argument and returns `{:ok, bmp}` on success, `{:error, reason}` otherwise.

  ## Examples

      iex(1)> BMP.read_file("mew.bmp")
      {:ok,
       mew.bmp
      -------
      BMP header:
        signature:          BM              | 42 4D                   | 2
        file size:          3.05 KiB        | 36 0C 00 00             | 4
        reserved                            | 00 00 00 00             | 4
        data offset:        54 B            | 36 00 00 00             | 4

      DIB header:
        header size:        40 B            | 28 00 00 00             | 4
        image size:         32x32           | 20 00 00 00 20 00 00 00 | 8
        planes:             1               | 01 00                   | 2
        color depth:        24 bit          | 18 00                   | 2
        compression:        type 0          | 00 00 00 00             | 4
        compressed size:    3.0 KiB         | 00 0C 00 00             | 4
        x resolution:       3780 px/m       | C4 0E 00 00             | 4
        y resolution:       3780 px/m       | C4 0E 00 00             | 4
        used colors:        0               | 00 00 00 00             | 4
        important colors:   0               | 00 00 00 00             | 4

      color table:          0 B

      raster data:          FF FF FF FF FF FF FF FF FF FF FF FF ...   | 3072
      }
      iex(2)> BMP.read_file("xeon.jpg")
      {:error, :not_a_bmp}
  """
  @spec read_file(Path.t()) :: {:ok, bmp()} | {:error, atom()}
  def read_file(path) do
    with {:ok, data} <- File.read(path),
         {:ok, bmp} <- parse(data) do
      {:ok, %{bmp | name: Path.basename(path)}}
    else
      error -> error
    end
  end

  @spec parse(binary()) :: {:ok, bmp()} | {:error, atom()}
  def parse(data) do
    with header <- :binary.part(data, 0, 14),
         signature <- :binary.part(header, 0, 2),
         info_header <- :binary.part(data, 14, 40) do
      if signature == "BM" do
        depth =
          :binary.part(info_header, 12, 2)
          |> :binary.decode_unsigned(:little)

        {color_table?, color_table_size?} =
          cond do
            depth <= 8 ->
              colors_number =
                :binary.copy(<<0xFF>>, div(depth, 8))
                |> :binary.decode_unsigned()

              {
                :binary.part(data, 54, 4 * colors_number),
                4 * colors_number
              }

            true ->
              {<<>>, 0}
          end

        compressed_size = :binary.part(info_header, 20, 4)

        {:ok,
         %BMP{
           bmp_header: %BMPHeader{
             file_size: :binary.part(header, 2, 4)
           },
           dib_header: %DIBHeader{
             width: :binary.part(info_header, 4, 4),
             height: :binary.part(info_header, 8, 4),
             color_depth: :binary.part(info_header, 14, 2),
             compression: :binary.part(info_header, 16, 4),
             compressed_size: compressed_size,
             x_pixels_per_m: :binary.part(info_header, 24, 4),
             y_pixels_per_m: :binary.part(info_header, 28, 4),
             used_colors: :binary.part(info_header, 32, 4),
             important_colors: :binary.part(info_header, 36, 4)
           },
           color_table: color_table?,
           raster_data:
             :binary.part(
               data,
               54 + color_table_size?,
               :binary.decode_unsigned(compressed_size, :little)
             ),
           name: nil
         }}
      else
        {:error, :not_a_bmp}
      end
    end
  end

  @doc """
  Writes `bmp` to the file `path`.

  Returns `:ok` if successful, `{:error, reason}` otherwise.
  """
  @spec write_file(bmp(), Path.t()) :: :ok | {:error, File.posix()}
  def write_file(bmp, path) do
    write_file(&File.write/2, bmp, path)
  end

  @doc """
  Writes `bmp` to the file `path`.

  Returns `:ok` if successful, raises `File.Error` exception otherwise.
  """
  @spec write_file!(bmp(), Path.t()) :: :ok
  def write_file!(bmp, path) do
    write_file(&File.write!/2, bmp, path)
  end

  defp write_file(func, bmp, path) do
    func.(
      path,
      Enum.join([
        bmp.bmp_header.signature,
        bmp.bmp_header.file_size,
        bmp.bmp_header.reserved,
        bmp.bmp_header.data_offset,
        bmp.dib_header.dib_header_size,
        bmp.dib_header.width,
        bmp.dib_header.height,
        bmp.dib_header.planes,
        bmp.dib_header.color_depth,
        bmp.dib_header.compression,
        bmp.dib_header.compressed_size,
        bmp.dib_header.x_pixels_per_m,
        bmp.dib_header.y_pixels_per_m,
        bmp.dib_header.used_colors,
        bmp.dib_header.important_colors,
        bmp.color_table,
        bmp.raster_data
      ])
    )
  end
end
