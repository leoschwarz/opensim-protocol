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

  | Frequency | Length | Encoding            |
  | --------- + ------ | ------------------- |
  | High      | 1 B    | 0x01-0xfe           |
  | Medium    | 2 B    | 0xff 0x01-0xfe      |
  | Low       | 4 B    | 0xff 0xff 0x00-0xff |
  | Fixed     | 4 B    | 0xff 0xff 0x00-0xff |

Note hat Low and Fixed frequency messages describe the same range of messages and Fixed is kept only for legacy reasons.

# Sources:
* http://wiki.secondlife.com/wiki/Message (accessed 2017-04-03)
