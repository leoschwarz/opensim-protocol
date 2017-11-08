This is to be integrated into the surface.md file at a later time.

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
| stride                  | patch_size | layer_type |
| 16 bit                  | 8 bit      | 8 bit      |
+------------+------------+------------+------------+
```

## patch_header
word_bits := quantity_wbits & 0xf + 2

TODO: quantity_wbits, word_bits

There are normal patches and large patches. They differ in the surface area size. Here
the main difference is the length of patch_x, patch_y which are both 5 bit for normal
size regions and both 16 bit for large size regions.

```
+----------------+-----------+--------+-------------+-------------+
| quantity_wbits | dc_offset | range  | patch_x     | patch_y     |
| 8 bit          | 32 bit    | 16 bit | 5 or 16 bit | 5 or 16 bit |
+----------------+-----------+--------+-------------+-------------+
```

assert! i,j < mPatchesPerEdge (TODO: mPatchesPerEdge)

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

## Decompressing
After extracting the patch values according to the above scheme they have to be decompressed.

Remark (TODO remove) The code is making things rather complicated by using both patch_size and LARGE_PATCH_SIZE=32 more or less
interchangeably.

LARGE_PATCH_SIZE = 32

### Matrices
The following expressions for matrix elements assume zero based indexing.

patch_dequantize_table: F32[LARGE_PATCH_SIZE * LARGE_PATCH_SIZE] matrix → stored col major in LL code
patch_dequantize_table[i, j] = 1. + 2. * (i+j) for 0 ≤ (i,j) < patch_size;

patch_icosines: F32[LARGE_PATCH_SIZE * LARGE_PATCH_SIZE] matrix → stored col major in LL code
patch_icosines[i, j] = cos( (2. * i + 1.) * j * PI/(2. * size) );

decopy_matrix: S32[LARGE_PATCH_SIZE * LARGE_PATCH_SIZE] matrix → stored col major in LL code,
looks like:

+-+-+-+
|0|2|3|
+-+-+-+
|1|4|7|
+-+-+-+
|5|6|8|
+-+-+-+

Note that for a larger matrix 6, 7, 8 would be at different positions, since after 5 the numbering wouldn't continue to the right side but to the lower side befor going up-right diagonally.

expression: Either compute by walking through the matrix, like it was done in build_decopy_matrix, or maybe find some nice expression based on Cantor's pairing formula (but reverse every uneven diagonal).

### decompress_patch
patch_in: S32[patch_size * patch_size];
patch_out: F32[patch_size * patch_size];

block: F32[LARGE_PATCH_SIZE * LARGE_PATCH_SIZE]
block[k] = patch_in[decopy_matrix[k]] * dequantize_table[k]; for 0 <= k < patch_size * patch_size

if patch_size == 16
    idct_patch(block)
else
    idct_patch_large(block) 

// TODO: stride makes this part more complicated than it has to:
F32 mult = ooq * patch_range; // TODO
F32 addval = // TODO
for (S32 j=0; j < patch_size; j++)
    for (S32 i=0; i < patch_size; ++i)
        patch[j*stride + i] = block[j*size + i] * mult + addval;

#### idct_patch:
NORMAL_PATCH_SIZE = 16;
LARGE_PATCH_SIZE = 32;

bonus points if this can be implemented using generics where the generic type just returns the patch size
and the code will be generated replacing the patch size with the corresponding value
→ can this be done in Rust using associated constants?

// Can be used generically for large regions too by substituting NORMAL_PATCH_SIZE := LARGE_PATCH_SIZE
idct_patch(F32 * block)
    // This line is initalized with this size regardless of the region size, which I'm not exactly
    // sure why they would do it like this?
    F32 temp[LARGE_PATCH_SIZE * LARGE_PATCH_SIZE] = {0};
    for (int i=0; i<NORMAL_PATCH_SIZE; ++i)
        idct_column(block, temp, i);
    for (int i=0; i<NORMAL_PATCH_SIZE; ++i)
        idct_line(temp, block, i);

// Can be used generically for large regions too by substituting NORMAL_PATCH_SIZE := LARGE_PATCH_SIZE
idct_column(data_in, data_out, column):
    for (int n=0; n<NORMAL_PATCH_SIZE; ++n) {
        F32 total = sqrt(2.)/2. * data_in[column];
        for (S32 x=1; x<NORMAL_PATCH_SIZE; ++x)
            total += data_in[column + x*NORMAL_PATCH_SIZE] * patch_icosines[n + x*NORMAL_PATCH_SIZE];
        data_out[NORMAL_PATCH_SIZE*n + column] = total;
    }

// Can be used generically for large regions too by substituting NORMAL_PATCH_SIZE := LARGE_PATCH_SIZE
idct_line(data_in, data_out, line)
    line_offset := line * NORMAL_PATCH_SIZE;
    for (int n=0; n<NORMAL_PATCH_SIZE; ++n) {
        F32 total = sqrt(2.)/2. * data_in[line_offset];
        for (S32 x=1; x<NORMAL_PATCH_SIZE; ++x)
            total += data_in[line_offset + x] * patch_icosines[n + x * NORMAL_PATCH_SIZE];
        data_out[line_offset + n] = total * (2. / NORMAL_PATCH_SIZE);
    }





# Methods of interest
Examine these further:


- indra/newview/llviewerregion.cpp
  - LLViewerRegion::unpackRegionHandshake()
- indra/newview/llsurface.cpp
  - LLSurface::decompressDCTPatch()
- indra/newview/llsurface.h
  → incline docstrings
- indra/llmessage/patch_code.cpp
  - decode_patch()
  - decompress_patch()
