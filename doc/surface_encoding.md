- There are RegionInfo and RegionHandshake messages which provide various information,
  see LLViewerRegion::unpackRegionHandshake, however so far to me it's not clear how to
  get that response from the viewer, does the client have to send the handshake first?
  → The viewer uses this information so that cache data can be stored at a relevant
    location on the disk.

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
