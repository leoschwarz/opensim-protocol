# Textures
## Encoding
The default encoding for textures is JPEG 2000, however it's possible that textures are encoded in any one of the following formats, marked by their file name's extension:

| Encoding | Extensions           |
| -------- | -------------------- |
| BMP      | .bmp                 |
| TGA      | .tga                 |
| JPEG2000 | .j2c, .jp2, .texture |
| JPEG     | .jpg, .jpeg          |
| DXT      | .mip, .dxt           |
| PNG      | .png                 |

## Fetching
There are two different ways in which textures are fetched from a simulator, either through HTTP
or llUDP.

### HTTP
The request url is constructed according to:

TODO: This is not yet finished because we have to read the capabilities from the region.

base_url := region->getViewerAssetUrl() or else region->getHttpUrl()
if not empty (base_url):
    request_url := base_url + "/?texture_id=" + texture_id

### UDP

## Points raised by inspecting current implementations
- Texture fetching is probably the most relevant part for bandwidth throttling in the whole
  network stack, so if the client should be able to set this value, the number of bytes transmitted
  would have to be collected in some way or the other. (The code in the Linden based viewer is rather
  rigorous about this, but I feel that something easier would already work, as long as you expose
  the API to reset counting, because these kinds of stats have to be recorded separately after region
  changes or something like that. TODO: But revise what I wrote here, this is just my first idea I
  had by looking at the current implementation's code. keyword "Send Metrics")
- One more feature I've found is resource blacklisting, but I'm not completely sure why this should
  be regulated in the texture fetching system, I believe this should be done by the one calling it?

Construction of the HTTP request:
base_url := region->getViewerAssetUrl() or else region->getHttpUrl()
if not empty (base_url):
    request_url := base_url + "/?texture_id=" + texture_id

→ client: RequestImage { AgentData, RequestImage { uuid, discardLevel, priority } )}
→ server: ImagePacket

request: req->mType, 0 = reset

### There are multiple kinds of texture requests (see llviewertexture.h)
enum FTType
{
	FTT_UNKNOWN = -1,
	FTT_DEFAULT = 0, // standard texture fetched by id.
	FTT_SERVER_BAKE, // texture produced by appearance service and fetched from there.
	FTT_HOST_BAKE, // old-style baked texture uploaded by viewer and fetched from avatar's host.
	FTT_MAP_TILE, // tiles are fetched from map server directly.
	FTT_LOCAL_FILE // fetch directly from a local file.
};


## TODO
- Check what is implemented by OpenSim, does it also implement the HTTP texture service?
  Depending on this the documentation effort could be reduced by only focusing on the relevant
  part of the protocol.
- Research what kind of issue BUG-3323/SH-4375 is and what they are trying to fix with the 32 MB heuristic?
- Figure out where to get the url or object handle/id to retrieve the textures from. (Region data/udp messages/or where)
- Accessible listing of sources.

# Sources:
- indra/newview/lltexturefetch.{cpp,h} (actually the cpp file in the firestorm viewer is very well documented! figure out who did it to give credit)
- llimage/llimageworker.{cpp,h} (not so much documented, but important because it describes some kind of image decoding)

