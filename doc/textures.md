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

## Texture types
There are 3 kinds of textures:

- Normal: Normal in-world object textures
- Baked: Avatar textures
- ServerBaked: Server baked avatar textures

## Retrieval
There are two different ways in which textures are fetched from a simulator, either through HTTP or llUDP.

### HTTP
TODO: Is the texture id specified with hyphens or does it not matter?
A texture with the id `texture_id` can be retrieved via HTTP from the URL `base_url + "/?texture_id=" + texture_id.hex`.

where
`base_url := region->getViewerAssetUrl() or else region->getHttpUrl()`

TODO: This is not yet finished because we have to read the capabilities from the region.

### llUDP
- Some shading information and a specification of the texture to be used is provided in `*ObjectUpdate` messages. (It's also included in the `ObjectProperties` message.
- The mechanism for retrieving the texture data from the server is implemented in the `*Xfer*` messages.

Remarks:
- The OpenMetaverse code waits 15s if Xfer content data is received before a relevant header was sent, before it discards the received data.
- Even according to the OpenMetaverse code: the Xfer system is "almost deprecated", so maybe it makes sense to first implement the HTTP texture service, and then see if this is needed at all.

## Default textures
TODO: e.g. how to retrieve ground and skymap textures?
They are retrieved like all other textures, and their ids are specified in some special message by the sim.

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
- What kind of textures are these even? I've found cubemaps, but are there also single 2D textures or how is this managed?

# Sources:
- indra/newview/lltexturefetch.{cpp,h} (actually the cpp file in the firestorm viewer is very well documented! figure out who did it to give credit)
- llimage/llimageworker.{cpp,h} (not so much documented, but important because it describes some kind of image decoding)
- OpenMetaverse/TexturePipeline.cs: Contains a full texture request pipeline.
