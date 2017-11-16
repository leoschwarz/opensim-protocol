# Some notes on the LL viewer code base.
A couple of remarks for studying the code in the LL viewer code base.

## Endianness
So far all multi-byte fields in the protocol I encountered were stored in little endian order. The code contains define guards to support platforms utilizing each of the two possible endianness. There is a LL_BIG_ENDIAN and LL_LITTLE_ENDIAN define which are set to 1 if the platform is of the specific endianness and not defined when the platform isn't.
