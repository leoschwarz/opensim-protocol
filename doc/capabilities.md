Capabilities is a bi-directional REST protocol, for non real-time transactions such as teleporting or group messaging.

# Encoding
Data is encoded in LLSD. (Actually both binary, XML, and JSON serialization can be used.)

# Protocol
At the beginning the viewer requests the endpoint urls for various capabilities by sending an LLSD array of strings specifying the names of the capabilities. (TODO: channel)

On success the sim returns a LLSD map (String, URI) specifying the endpoints for each of the capabilities. The OpenMetaverse code fails on 404 error, but retries in any other case.

# Capabilities
There are many capabilities with different purposes, which right now I cannot cover all here (TODO). Also avoid documenting deprecated capabilities, for example why are there `GetMesh` and `GetMesh2`?

The main URL to retrive the capabilities from (seed caps) is:
- LoginResponse
- EstablishAgentCommunication message: SeedCapability as string. (TODO, this is the case when neighboring sims request an agent to make a connection to it.)

## GetTexture
See textures.md for more information on how textures are retrieved over HTTP, this essentially specifies the base URI for said retrieval.

ContentType: "image/x-j2c".
CapsTimeout: 60s (to me this seems a bit excessive → except if it's the time for the complete transfer and not just the timeout for not making any progress.)

In the event of success ImageType::ServerBaked and AssetType::Texture is obtained.

## EventQueueGet
TODO
This one is a special capability as it provides an event stream for the capability systemo r something like that.

# Properties

Note: This is probably something different again?
It was my initial result from inspecting:
`indra/neview/llviewerregion.cpp (LLViewerRegion::setCapability)`

| Key                       | Description |
| ------------------------- | ----------- |
| EventQueueGet             | |
| UntrustedSimulatorMessage | |
| SimulatorFeatures         | |
| ViewerAsset               | The simulator can serve assets over HTTP. |
| GetTexture                | The simulator can serve assets over UDP.  |

# Sources
- OpenMetaverse/Caps.cs
