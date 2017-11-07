# Messages
Messages describe the encoding and structure of information passed through individual packets. There is a multitude of packets for various aspects of the client-server interaction, however they all share the same fundamental structure.

## TODO
* In this documentation we are developing our own format to provide appropriate and extensive documentation for all the messages of the protocol. Right now the (XML) format is not developed yet and tooling will yet have to be made.
* Information on serialization of the messages.

## Message number
Every message type has a specific message number, identifying the message and its layout.
It's either 1, 2 or 4 bytes long, identified by so called frequencies in the Linden message template.
The bytes are sent in big endian order.

Linden message template terminology:

| Frequency | Length | Encoding                |
| --------- | ------ | ----------------------- |
| High      | 1 B    | 0x01-0xfe               |
| Medium    | 2 B    | 0xff 0x01-0xfe          |
| Low       | 4 B    | 0xff 0xff 0x0000-0xffff |
| Fixed     | 4 B    | 0xff 0xff 0x0000-0xffff |

Note hat Low and Fixed frequency messages describe the same range of messages and Fixed is kept only for legacy reasons.

# Data Types

| Name           | Description |
| -------------- | ----------- |
| Fixed (\d+)    | A byte array with fixed size specified in the spec. |
| Variable 1     | A byte array, with a preceeding byte determining the number of bytes that follow. |
| Variable 2     | A byte array, with two preceeding bytes (little endian unsigned) determining the number of bytes that follow. |
| U8,U16,U32,U64 | Unsigned integers in litte-endian order. |
| S8,S16,S32,S64 | Signed integers in little-endian order. |
| F32, F64       | Floating point numbers (little-endian order). |
| LLVector3      | Triplet of F32, 12 bytes long. |
| LLVector3d     | Triplet of F64, 24 bytes long. |
| LLVector4      | Quadruple of F32, 16 bytes long. |
| LLQuaternion   | Unit quaternion transmitted as triplet of F32. |
| LLUUID         | UUID in binary format, 16 bytes long. |
| BOOL           | 0 or 1, one byte long. |
| IPADDR         | IPv4 address, 4 bytes long. |
| IPPort         | U16 specifying a port number. |

# Sources:
* http://wiki.secondlife.com/wiki/Message (accessed 2017-04-03)
