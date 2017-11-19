- There are RegionInfo and RegionHandshake messages which provide various information,
  see LLViewerRegion::unpackRegionHandshake, however so far to me it's not clear how to
  get that response from the viewer, does the client have to send the handshake first?
  → The viewer uses this information so that cache data can be stored at a relevant
    location on the disk.


## Decompressing


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

F32 mult = (F32)patch_range / (F32)(1 << quant);
F32 addval = (F32)patch_range / 2. + dc_offset

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
