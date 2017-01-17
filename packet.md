# Packets
An UDP-based message system is used for communication between the client ("viewer") and server ("simulator").
TODO: Separate documentation entry for "messages".

## Packet format
Every packet begins with a six bytes long header.

```
+--------+--------+--------+--------+--------+--------+
| Flags  | Sequence number                   | Extra  |
+--------+--------+--------+--------+--------+--------+
```

* Flags: Only the four most significant bits of this byte are used, the others are sent as zero.

| Flag                | Value       | Description |
|---------------------|-------------|-------------|
| `MSG_APPENDED_ACKS` | 0x10        | TODO        |
| `MSG_RESENT`        | 0x20        | Set if the message has been resent because there was no timely ACK even though the message was sent with the `MSG_RELIABLE` flag. |
| `MSG_RELIABLE`      | 0x40        | Set if an ACK is to be sent on receiving this message. |
| `MSG_ZEROCODED`     | 0x80        | TODO        |

* Sequence number: A 32-bit number in big-endian order. They are unique to each connection and each direction, and are incremented on each message sent.
* Extra: Specifies the length of additional extra header information in bytes following directly after this byte. In practice this is always zero. If it were different clients not expecting extra headers can skip this number of bytes.

# Sources
* http://lib.openmetaverse.co/wiki/Protocol_(network) (accessed 2017-01-17)
* http://wiki.secondlife.com/wiki/Packet_Layout (accessed 2017-01-17)
* http://wiki.secondlife.com/wiki/Packet_Accounting (accessed 2017-01-17)

