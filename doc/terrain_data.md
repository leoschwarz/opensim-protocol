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

### Encoding
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


Here the encoding of the patch
Different layers are encoded differently.

For the LAND and AURORA_LAND layers a variant of DCT (discrete cosine transform) is used.

TODO: expand

 TODO: move to right place
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
