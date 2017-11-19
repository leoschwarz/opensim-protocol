# Terrain Data
## Regions
There are two main types of regions in OpenSimulator.

- *Normal regions*: These always have a side length of 256m.
- [*VarRegion*](http://opensimulator.org/wiki/Varregion): These can have any side length k×256m where k in {1, ..., 32}. (256m to 8192m.)

Regions are always square. They mainly differ in how the terrain data is encoded for them, which is mostly due to historic circumstance.

## Layer types
The following types of layers are known:

| Name      | Code (u8) |
| --------- | --------- |
| LAND      | 'L' (76)  |
| WIND      | '7' (55)  |
| CLOUD     | '8' (56)  |
| WATER     | 'W' (87)  |
| VAR_LAND  | 'M' (77)  |
| VAR_WIND  | 'X' (88)  |
| VAR_CLOUD | '9' (57)  |
| VAR_WATER | ':' (58)  |

## Land and VarLand
These layers encode a heightmap of the region, where there is one height value for each square of sidelength 1 meter. (TODO: I'm not sure yet how these values per square are to be mapped to a 3D representation. Are these values elevations of the point in the center of the squaremeter? And how is the grid to be interpolated?)

The data is first split into square shaped patches, aligned in a regular grid over the region, where the side length is 16m for normal regions and 32m for VarRegions. They also each store one value per square meter.

The data is compressed using discrete cosine transformation. The following subsections explain how to retrieve the original data.

### Binary encoding
Multi byte values are encoded in little endian fashion.
TODO: Describe partial values (u10) somewhere.

#### patch_group_header
```text
+------------+------------+------------+------------+
| stride                  | patch_size | layer_type |
| 16 bit                  | 8 bit      | 8 bit      |
+------------+------------+------------+------------+
```

- One instance per sequence of patches (i.e. per message), at the very beginning.

#### patch_header
```text
+----------------+-----------------+--------+-------------+-------------+
| quantity_wbits | dc_offset [f32] | range  | patch_y     | patch_x     |
| 8 bit          | 32 bit          | 16 bit | 5 or 16 bit | 5 or 16 bit |
+----------------+-----------------+--------+-------------+-------------+
```

- One instance per patch.
- quantity_wbits:
-- If it equals 97 (0b0110_0001), it means no further patches are encoded.
-- Otherwise the first 4 bits equal `quant - 2` and the last 4 bits equal `word_bits - 2`.
   Only `quant` and `word_bits` will be needed in the following sections.
- dc_offset = z_min
- range = (z_max - z_min) + 1.0
- patch_x, patch_y < patches_per_region_edge

Followed by a sequence of up to patch_size² patch_value instances.

#### patch_value
```text
+---------+---------+---------+-------------------------------+
| exists  | not_eob | sign    | value [u32]                   |
| 1 bit   | 1 bit   | 1 bit   | word_bits bit (up to 18 bits) |
+---------+---------+---------+-------------------------------+
```

- If `exists=0`, the following 3 fields are not expressed, the value is zero, and the next patch_value follows.
- If `not_eob=1` there is a value, otherwise no more patch_value instances for this patch will follow and can be all set to zero.
- If `sign=1` parse the value as unsigned number and add the negative sign, otherwise leave the number positive.

### Inverting the discrete cosine transform
#### Tables
The following matrices of size patch_size×patch_size are needed when decoding.

```
patch_dequantize, patch_icosines: Matrix<f32, patch_size, patch_size>;
patch_dequantize[i, j] = 1. + 2. * (i+j) for 0 ≤ (i,j) < patch_size;
patch_icosines[i, j] = cos( (2. * i + 1.) * j * PI/(2. * size) );
```

`decopy_matrix: Matrix<usize, patch_size, patch_size>` is filled with fields numbered in a snake movement as in this sketch:
```text
+-+-+-+
|0|2|3|
+-+-+-+
|1|4|7|
+-+-+-+
|5|6|8|
+-+-+-+
```

#### Decompress patch
```text
patch_in: Matrix<u32, patch_size, patch_size>;
patch_out: Matrix<f32, patch_size, patch_size>;

block: Matrix<f32, patch_size, patch_size>;
block[k] = patch_in[decopy_matrix[k]] * patch_dequantize[k]; for 0 <= k < patch_size²

idct_patch(block, patch_size);

mult: f32 = (F32)patch_range / (F32)(1 << quant);
addval: f32 = (F32)patch_range / 2. + dc_offset
for (j=0; j < patch_size; j++)
    for (i=0; i < patch_size; ++i)
        patch[j*stride + i] = block[j*size + i] * mult + addval;
```

Main decoder:

```
idct_patch(mut block, patch_size)
    temp: Matrix<f32, patch_size, patch_size> = {0};
    for (i=0; i<patch_size; ++i)
        idct_column(block, temp, i)
    for (i=0; i<patch_size; ++i)
        idct_row(temp, block, i)

idct_column(data_in, mut data_out, column)
    for (n=0; n<patch_size; ++n)
        total: f32 = sqrt(2.)/2. * data_in[column, 0]
        for (x=1; x<patch_size; ++x)
            total += data_in[column, x] * patch_icosines[n, x]
        data_out[column, n] = total;

idct_row(data_in, mut data_out, row)
    for (n=0; n<patch_size; ++n)
        total: f32 = sqrt(2.)/2. * data_in[0, row];
        for (x=1; x<patch_size; ++x)
            total += data_in[x, row] * patch_icosines[n, x]
        data_out[n, row] = total * 2. / patch_size
```

TODO: move to right place and expand/correct
Each surface entity describes a square shape region.
A surface can have up to 8 optional neighbors in all directions (N, NE, E, SE, S, SW, W, NW).

```
                                   North
                 ___________________________________  _______
                /      /      /      /      /M*M-2 / /M*M-1 /
               /______/______/______/______/______/ /______/
              ___________________________________  _______
             /      /      /      /      /      / /      /
            /______/______/______/______/______/ /______/
  West     /      /      /      /      /      / /      /
          /______/______/______/______/______/ /______/   East
         /      /      /      /      /      / /      /
    _   /______/______/______/______/______/ /______/
    /| / M    / M+1  / M+2  / ...  / 2M-2 / / 2M-1 /        z
   /  /______/______/______/______/______/ /______/         ^  _ y
  j  / 0    / 1    / 2    / ...  / M-2  / / M-1  /          |  /|
    /______/______/______/______/______/ /______/           | /
                                |<-L->|                     |/
        i --->         South                                O------> x
```

M = patches_per_edge = 2^n + 1 where n is a natural number,
L = meters_per_grid

//M = grids_per_edge = 2^n + 1 where n is a natural number,
//L = meters_per_grid

One more row and column are stored in the north and the east to serve as a buffer, to bridge the gap
rendering adjacent surface entities, as indicated in the drawing.

# Sources
- newview/llsurface.{cpp, h}
- newview/llviewerregion.cpp (LLViewerRegion::LLViewerRegion)

TODO: 

From the UDP message `TeleportFinish` we obtain for OpenSim:
region_size_x : RegionSizeX as obtainable from OpenSim (Info message)
region_size_y : RegionSizeY as obtainable from OpenSim

TODO: there are other sources according to the OpenSim wiki also:
    EnableSimulator event message: add integers 'RegionSizeX' and 'RegionSizeY'
    CrossRegion event message: add integers 'RegionSizeX' and 'RegionSizeY' to 'RegionData' section.
    TeleportFinish event message: add integers 'RegionSizeX' and 'RegionSizeY' to 'Info' section.
    EstablishAgentCommunication event message: add integers 'region-size-x' and 'region-size-y'. 

