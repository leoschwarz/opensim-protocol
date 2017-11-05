This file aims to provide an overview over the various kinds of region data available, where they can be retrieved and how they are encoded.

- There are RegionInfo and RegionHandshake messages which provide various information,
  see LLViewerRegion::unpackRegionHandshake, however so far to me it's not clear how to
  get that response from the viewer, does the client have to send the handshake first?
  → The viewer uses this information so that cache data can be stored at a relevant
    location on the disk.

# Layer kinds
There are multiple kinds of layers. OpenSimulator implements the Aurora large region protocol extension of the original protocol,
in essence the Aurora layers are used for [Varregions](http://opensimulator.org/wiki/Varregion).

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

TODO: My current understanding is very limited, I only looked at (→ see newview/llvlmanager.cpp unpackData), so likely the layers other than
      LAND and WIND are used too but rather processed directly instead of first feeding it into the unpackData method.

# Land encoding
TODO: how is ordering of the patches achieved

For example the data could look like:
```
group_header patch_header patch patch patch patch_header patch patch patch_header patch 97u8
```

## patch_group_header
Every level data patch has a group header, regardless of which layer is described.

```
+------------+------------+------------+------------+
| stride                  | patch size | layer type |
| 16 bit                  | 8 bit      | 8 bit      |
+------------+------------+------------+------------+
```

## patch_header
word_bits := quantity_wbits & 0xf + 2

TODO: quantity_wbits, word_bits

There are normal patches and large patches, which differ in the length of patch_ids.
Which one is specific for each kind of layer data.

```
+----------------+-----------+--------+-------------------------------+
| quantity_wbits | dc_offset | range  | patch_ids                     |
| 8 bit          | 32 bit    | 16 bit | 10 (normal) or 32 (large) bit |
+----------------+-----------+--------+-------------------------------+
```

If quantity_wbits equals 97u8, it means all data has been transmitted.


patch areas:
i,j : what are these?

mPatchesPerEdge = (mGridsPerEdge - 1) / mGridsPerPatchEdge;
mNumberOfPatches = mPatchesPerEdge

## patch
Consists of a sequence of up to patch_size² patches, however it's possible that the sequence
terminates prematurely. (TODO: Is it possible that some patches don't exist, or does it just
mean that they weren't transmitted yet?)

```
+---------+---------+---------+---------------+
| exists  | not_eob | sign    | value         |
| 1 bit   | 1 bit   | 1 bit   | 8 bit         |
+---------+---------+---------+---------------+
```

If exists=0, this patch is zero, the following 3 fields are not specified and the next patch block follows immediately, in that case skip the following information.

If not_eob=1 parsing is continued, however if it equals 0 it means that we reached the EOB and there
are no more patches to be decoded.

The sign bit specifies the sign to be added to the 8 bit unsigned value, sign=1 is negative and sign=0 is positive.

### Decompressing
After extracting the patch values according to the above scheme they have to be decompressed.

The code in indra/llmessage/patch_idct.cpp is rather intricate and highly specific, it's almost
impossible to write a spec without copying all the code inside of that file but it's part of the network protocol.

LARGE_PATCH_SIZE = 32

TODO
dimensions ???
        if (b_large_patch)
        {
            i = ph.patchids >> 16; //x
            j = ph.patchids & 0xFFFF; //y
        }
        else
        {
            i = ph.patchids >> 5; //x
            j = ph.patchids & 0x1F; //y
        }

assert! i,j < mPatchesPerEdge (TODO: mPatchesPerEdge)



# Methods of interest
Examine these further:

- indra/newview/llviewerregion.cpp
  - LLViewerRegion::unpackRegionHandshake()
- indra/newview/llsurface.cpp
  - LLSurface::decompressDCTPatch()
- indra/llmessage/patch_code.cpp
  - decode_patch()
  - decompress_patch()
