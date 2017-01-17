# Packets
An UDP-based message system is used for communication between the client ("viewer") and server ("simulator").

##TODO
* Separate documentation entry for "messages".
* Sequence numbers are stored in 32-bit integers, but are said in many places in the documentation to actually just be 24-bit numbers which are zero padded.

## Packet format
Every packet begins with a six bytes long header.

```
+--------+--------+--------+--------+--------+--------+
| Flags  | Sequence number                   | Extra  |
+--------+--------+--------+--------+--------+--------+
```

* **Flags**: Only the four most significant bits of this byte are used, the others are sent as zero.

| Flag                | Value       | Description |
|---------------------|-------------|-------------|
| `MSG_APPENDED_ACKS` | 0x10        | Set if there are appended acks. See section on ACKs. |
| `MSG_RESENT`        | 0x20        | Set if the message has been resent because there was no timely ACK even though the message was sent with the `MSG_RELIABLE` flag. |
| `MSG_RELIABLE`      | 0x40        | Set if an ACK is to be sent on receiving this message. |
| `MSG_ZEROCODED`     | 0x80        | TODO        |

* **Sequence number**: A 32-bit number in big-endian order. They are unique to each connection and each direction, and are incremented on each message sent.
* **Extra**: Specifies the length of additional extra header information in bytes following directly after this byte. In practice this is always zero. If it were different clients not expecting extra headers can skip this number of bytes.

## ACKs
An ack essentially consists of the 32-bit big-endian sequence number of the packet that is to be acknowledged.

ACKs can be sent in two ways:
* PacketAck: This is a specialized packet. TODO.
* Appended ACKs: The very last byte of the UDP packet indicates the number of 32-bit ACKs appended just in front of this byte.

# References
* http://lib.openmetaverse.co/wiki/ACK (accessed 2017-01-17)
* http://lib.openmetaverse.co/wiki/Protocol_(network) (accessed 2017-01-17)
* http://wiki.secondlife.com/wiki/Packet_Accounting (accessed 2017-01-17)
* http://wiki.secondlife.com/wiki/Packet_Layout (accessed 2017-01-17)

