# opensim-protocol

This project is an unofficial effort to document the protocol used by OpenSimulator/SecondLife virtual world.

Please be aware that these findings reflect my personal understanding of the protocol and there are likely going to be multiple mistakes.

Also consider this a steady work in progress. If you are interested in contributing let me know through email or the issue tracker and I can help you get started.

## Historic Notes

Originally I started this project to inject some documentation into generated code in my Rust implementation of the full networking stack [opensim-networking](https://github.com/leoschwarz/opensim-networking).

The biggest previous effort on providing an open source implementation (in C#) and some documentation of the protocol, has been made by the [libOpenMetaverse](https://github.com/openmetaversefoundation/libopenmetaverse) project. Their implementation is currently used by OpenSimulator, and can be used as a de-facto reference for new implementations.

Even though the protocol has been developed at Linden Research we refer to it as the `opensim-protocol` because this project's goals is to track the opensim flavor of the project should there be incompatible changes in the future.

## Disclaimer

Please be aware that any documents provided in the scope of this project reflect a personal understanding of the protocol, it is possible and likely that the real protocol used by software in the wild diverges from these findings.

Second Life is a trademark of Linden Research, Inc. This project and the authors are not affiliated with or sponsored by Linden Research.


