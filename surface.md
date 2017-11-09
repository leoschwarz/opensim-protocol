# Surface
This spec describes how surface information (land elevation, water, etc) is encoded.

## Geometry
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

M = grids_per_edge = 2^n + 1 where n is a natural number,
L = meters_per_grid

One more row and column are stored in the north and the east to serve as a buffer, to bridge the gap
rendering adjacent surface entities, as indicated in the drawing.

## Layer types
There are multiple kinds of layers, which describe different aspects of surface information and are encoded and compressed differently.
The [Varregion](http://opensimulator.org/wiki/Varregion) extension in OpenSim was originally developed in a fork called Aurora Sim and for the sake of documenting the protocol we stick to this naming.
The following types of layers are known:

| Name         | Code (u8) | Large Region |
| ------------ | --------- | ------------ |
| LAND         | 'L' (76)  | false        |
| WIND         | '7' (55)  | special      |
| CLOUD        | '8' (56)  | no patches?  |
| WATER        | 'W' (87)  | no patches?  |
| AURORA_LAND  | 'M' (77)  | true         |
| AURORA_WIND  | 'X' (88)  | special      |
| AURORA_CLOUD | '9' (57)  | no patches?  |
| AURORA_WATER | ':' (58)  | no patches?  |

TODO: Currently only LAND and AURORA_LAND data is going to be described in further detail, however the other layers are also important and should be covered somewhere.

## Parameters
The following parameters are going to be used in the description of the encoding of surface data:

TODO: Improve this table and remove everything not needed later.

| name                 | LL viewer             | description |
| -----------------    | --------------------- | ----------- |
| cell_count_per_edge  | mGridsPerEdge         | M in the above drawing. |
| cell_width           | mMetersPerGrid        | Length of one grid cell. `meters_per_grid = width / (grids_per_edge - 1)`  |
| surface_width        | width, mMetersPerEdge | Length of the surface into one direction in meters. |

TODO: 

From the UDP message `TeleportFinish` we obtain for OpenSim:
region_size_x : RegionSizeX as obtainable from OpenSim (Info message)
region_size_y : RegionSizeY as obtainable from OpenSim

| grids_per_patch_edge | mGridsPerPatchEdge  | WOLRD_PATCH_SIZE = 32 |
| patches_per_edge     | mPatchesPerEdge     | Number of patches on one side of a region. |
mPatchesPerEdge = (mGridsPerEdge - 1) / mGridsPerPatchEdge;
| number_of_patches    | mNumberOfPaches     |  |
| min_z                | mMinZ               | Minimum z for this region (during the session) |
| max_z                | mMaxZ               | Maximum z for this region (during the session) |


# Sources
- newview/llsurface.{cpp, h}
- newview/llviewerregion.cpp (LLViewerRegion::LLViewerRegion)

