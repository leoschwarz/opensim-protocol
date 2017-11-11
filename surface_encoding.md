This is to be integrated into the surface.md file at a later time.

This file aims to provide an overview over the various kinds of region data available, where they can be retrieved and how they are encoded.

- There are RegionInfo and RegionHandshake messages which provide various information,
  see LLViewerRegion::unpackRegionHandshake, however so far to me it's not clear how to
  get that response from the viewer, does the client have to send the handshake first?
  → The viewer uses this information so that cache data can be stored at a relevant
    location on the disk.

# Land encoding
Land surface data is encoded using discrete cosine transformation.
In the following sections the encoding of data and algorithms for inverting the transformation are described.

The binary data for a patch encompasses first a group_header, followed by a sequence of patch_header and patch_data, each described in the succinct sections:

## patch_group_header
Every level data patch has a group header, regardless of which layer is described.
All multi-bytes values are to be read in little endian order, if they don't align with full bytes [TODO].

```
+------------+------------+------------+------------+
| stride                  | patch_size | layer_type |
| 16 bit                  | 8 bit      | 8 bit      |
+------------+------------+------------+------------+
```

## patch_header

There are normal patches and large patches. They differ in the surface area size. Here
the main difference is the length of patch_x, patch_y which are both 5 bit for normal
size regions and both 16 bit for large size regions.

```
+----------------+-----------+--------+-------------+-------------+
| quantity_wbits | dc_offset | range  | patch_y     | patch_x     |
| 8 bit          | 32 bit    | 16 bit | 5 or 16 bit | 5 or 16 bit |
+----------------+-----------+--------+-------------+-------------+
```

quantity_wbits has two main functions:

- if it equals the value 97u8 (0b0110_0001) it signals that there are no more patches following
- the first for bits equal `quant - 2` and the last for bits equal `word_bits - 2`, when this
  expansion is done the full value of quantity_wbits is not needed anymore.


assert! patch_x, patch_y < mPatchesPerEdge (TODO: mPatchesPerEdge)
→ FIXME: This assertion currently doesn't hold in the Rust implementation.

TOOD: Meaning of (patch_x, patch_y)

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
TODO: There is still some confusion about the stride header value used when computing the output, and whether we really have to use the same size matrices for any of the two region sizes or if this is just a relict of ungeneric code? (Right now I feel like it might be mostly the latter issue.)

The following expressions for matrix elements assume zero based indexing and are stored in col major order in the original C++ code.

patch_dequantize_table: F32[LARGE_PATCH_SIZE * LARGE_PATCH_SIZE] matrix
patch_dequantize_table[i, j] = 1. + 2. * (i+j) for 0 ≤ (i,j) < patch_size;

patch_icosines: F32[LARGE_PATCH_SIZE * LARGE_PATCH_SIZE] matrix
patch_icosines[i, j] = cos( (2. * i + 1.) * j * PI/(2. * size) );

decopy_matrix: S32[LARGE_PATCH_SIZE * LARGE_PATCH_SIZE] matrix
looks like:
```text
+-+-+-+
|0|2|3|
+-+-+-+
|1|4|7|
+-+-+-+
|5|6|8|
+-+-+-+
```

Note that for a larger matrix 6, 7, 8 would be at different positions, since after 5 the numbering wouldn't continue to the right side but to the lower side befor going up-right diagonally.

expression: Either compute by walking through the matrix, like it was done in build_decopy_matrix, or maybe find some nice expression based on Cantor's pairing formula (but reverse every uneven diagonal).

### decompress_patch
```text
patch_in: S32[patch_size * patch_size];
patch_out: F32[patch_size * patch_size];

block: F32[LARGE_PATCH_SIZE * LARGE_PATCH_SIZE]
block[k] = patch_in[decopy_matrix[k]] * dequantize_table[k]; for 0 <= k < patch_size * patch_size

if patch_size == 16
    idct_patch(block)
else
    idct_patch_large(block) 

// TODO simplify mult and addval expressions as much as possible.
F32 mult = ooq * patch_range; // TODO
    where F32 ooq = 1.f/(1 << quant);
F32 addval = mult * ((F32) 1 << (quant - 1)) + dc_offset;

for (S32 j=0; j < patch_size; j++)
    for (S32 i=0; i < patch_size; ++i)
        patch[j*stride + i] = block[j*size + i] * mult + addval;
```

#### idct_patch:

```text
NORMAL_PATCH_SIZE = 16;
LARGE_PATCH_SIZE = 32;

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
```

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
