# Packets
Packets between the viewer and server are transmitted via UDP.
Here the structure of such packages is described.

##TODO
* Sequence numbers are stored in 32-bit integers, but are said in many places in the documentation to actually just be 24-bit numbers which are zero padded.
* How are UDP packets which don't fit into the max size of UDP packets handled. Are they just split up in some way and does each of the new packets have its
  own headers? Or will we have to detect this somehow?

## Packet header
Every packet begins with a six bytes long header.

```
+--------+--------+--------+--------+--------+--------+
| Flags  | Sequence number                   | Extra  |
+--------+--------+--------+--------+--------+--------+
```

* **Flags**: Only the four most significant bits of this byte are used, the others are sent as zero.

| Flag                | Value       | Description |
|---------------------|-------------|-------------|
| `PACKET_APPENDED_ACKS` | 0x10        | Set if there are appended acks. See section on ACKs. |
| `PACKET_RESENT`        | 0x20        | Set if the message has been resent because there was no timely ACK even though the message was sent with the `PACKET_RELIABLE` flag. |
| `PACKET_RELIABLE`      | 0x40        | Set if an ACK is to be sent on receiving this message. |
| `PACKET_ZEROCODED`     | 0x80        | Set if in the message body (i.e. everything except the header and potentially appended ACKs, but also including the message number at the beginning of the message) zero bytes are compressed. This is achieved by replacing every sequential occurence of one or more zero bytes with first a single zero byte and then a byte counting the number of zero bytes which were replaced by this single zero. |

* **Sequence number**: A 32-bit number in big-endian order. They are unique to each connection and each direction, and are incremented on each message sent.
* **Extra**: Specifies the length of additional extra header information in bytes following directly after this byte. In practice this is always zero. If it were different clients not expecting extra headers can skip this number of bytes.

## Packet body
The packet body consists of a message, which is described in further detail in the documentation page [message](message.md).

## ACKs
An ack essentially consists of the 32-bit big-endian sequence number of the packet that is to be acknowledged.

ACKs can be sent in two ways:
* PacketAck: This is a specialized packet. TODO how many can be sent this way.
* Appended ACKs: If the `PACKET_APPENDED_ACKS` flag is set, the very last byte of the UDP packet indicates the number of 32-bit ACKs appended just in front of this byte. So this way at most 255 acks can be appended.

# References
* http://lib.openmetaverse.co/wiki/ACK (accessed 2017-01-17)
* http://lib.openmetaverse.co/wiki/Protocol_(network) (accessed 2017-01-17)
* http://wiki.secondlife.com/wiki/Packet_Accounting (accessed 2017-01-17)
* http://wiki.secondlife.com/wiki/Packet_Layout (accessed 2017-01-17)

