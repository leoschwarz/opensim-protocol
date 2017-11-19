# Terrain Data
This document describes how terrain data (land elevation, water, etc) is encoded.

There are two kinds of simulator regions in OpenSimulator, varying in their encoding and size. Regardless all regions are square shaped.

*Normal regions* have a fixed size of 256x256m, while so called [VarRegions](http://opensimulator.org/wiki/Varregion) can have any side length in {256N meters: N∈{1,...,32}}.

## Layer types

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

## Land data
The land data consists of a heightmap of the entire region.

This data is split into so called (square shaped) patches, which are laid out in a regular grid over the region.

- *Normal regions* are described by 16x16 patches of size 16x16m each, where the patches store one value per square meter.
- *VarRegions* are described by as many 32x32m patches as are needed to describe the full region, here for each patch there is also one value per square meter.

TODO: The part until the next section is not yet finished.
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


## Parameters
The following parameters are going to be used in the description of the encoding of surface data:

TODO: Improve this table and remove everything not needed later.

In the Rust code the following parameters are used:

| Name (in spec)        | LL viewer             | description |
| --------------------- | --------------------- | ----------- |
| patches_per_edge      | mPatchesPerEdge       | Number of patches on one side of a region. 16 or 32 depending on region size. |
| patches_per_region    | mNumberOfPatches      | patches_per_edge * patches_per_edge |


Other variables are used in the code, however ideally they can be expressed in terms of patches_per_edge, like it was already done for patches_per_region.

| Name (in spec)        | LL viewer             | Description |
| --------------------- | --------------------- | ----------- |
|                       | grids_per_region_edge | region_size_x |
|                       | grids_per_patch_edge  | WORLD_PATCH_SIZE = 32 |

TODO: Figure out what mGridsPerEdge is
→ value provided by LLSurface::create(S32 grids_per_edge, ...) however it's unclear who even calls this function.

| cell_count_per_edge  | mGridsPerEdge         | M in the above drawing. |
| cell_width           | mMetersPerGrid        | Length of one grid cell. `meters_per_grid = width / (grids_per_edge - 1)`  |
| surface_width        | width, mMetersPerEdge | Length of the surface into one direction in meters. |

TODO: 

From the UDP message `TeleportFinish` we obtain for OpenSim:
region_size_x : RegionSizeX as obtainable from OpenSim (Info message)
region_size_y : RegionSizeY as obtainable from OpenSim

TODO: there are other sources according to the OpenSim wiki also:
    EnableSimulator event message: add integers 'RegionSizeX' and 'RegionSizeY'
    CrossRegion event message: add integers 'RegionSizeX' and 'RegionSizeY' to 'RegionData' section.
    TeleportFinish event message: add integers 'RegionSizeX' and 'RegionSizeY' to 'Info' section.
    EstablishAgentCommunication event message: add integers 'region-size-x' and 'region-size-y'. 

mPatchesPerEdge = (mGridsPerEdge - 1) / mGridsPerPatchEdge;
| min_z                | mMinZ               | Minimum z for this region (during the session) |
| max_z                | mMaxZ               | Maximum z for this region (during the session) |

## Encoding
Different layers are encoded differently.

For the LAND and AURORA_LAND layers a variant of DCT (discrete cosine transform) is used.

TODO: expand

