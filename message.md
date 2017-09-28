# Messages
Messages describe the encoding and structure of information passed through individual packets. There is a multitude of packets for various aspects of the client-server interaction, however they all share the same fundamental structure.

## TODO
* In this documentation we are developing our own format to provide appropriate and extensive documentation for all the messages of the protocol. Right now the (XML) format is not developed yet and tooling will yet have to be made.
* Information on serialization of the messages.

## Properties in the Linden Template
* **Frequency**: This essentially describes the length of the message id.
  | Value       | Description |
  | ----------- + ----------- |
  | High        | ID of the message is 1 byte long, in range [ TODO ]  |
  | Medium      | ID of the message is 2 bytes long, in range [ TODO ] |
  | Low         | ID of the message is 4 bytes long, in range [ TODO ] |
  | Fixed [U32] | Is considered a signal. |


# Sources:
* http://wiki.secondlife.com/wiki/Message (accessed 2017-04-03)
