########################################################################
# Type conversions and class definitions for the parsed template file. #
########################################################################

# Conversion from protocol spec types to Rust types.
TYPE_CONVERSIONS = {
    "U8" => "u8", "U16" => "u16", "U32" => "u32", "U64" => "u64",
    "S8" => "i8", "S16" => "i16", "S32" => "i32", "S64" => "i64",
    "F32" => "f32", "F64" => "f64",
    "LLUUID" => "Uuid",
    "IPADDR" => "Ip4Addr", "IPPORT" => "IpPort",
    "LLVector3" => "Vector3<f32>", "LLVector3d" => "Vector3<f64>", "LLVector4" => "Vector4<f32>",
    "LLQuaternion" => "Quaternion<f32>",
    "BOOL" => "bool",
    "Variable" => "Vec<u8>"
}

class Field
    attr_accessor :count
    def initialize(name, type, count)
        @name = name
        @type = type
        @count = count
    end

    # rust version of name
    def r_name
        name = @name.underscore
        keywords = ["type", "override", "final"]
        if keywords.include? name
            name + "_"
        else
            name
        end
    end

    def ll_name
        @name
    end

    def r_type
        if TYPE_CONVERSIONS.has_key? @type
            return TYPE_CONVERSIONS[@type]
        elsif @type == "Fixed"
            return "[u8; #{@count}]"
        else
            raise "Unknown LL Type: #{@type.inspect}"
        end
    end

    def ll_type
        if @type == "Variable"
            "Variable #{@count}"
        else
            @type
        end
    end

    def to_s
        "[Field: #{{name: @name, type: @type, count: @count}.inspect}]"
    end
end

class Block
    attr_accessor :fields, :quantity, :quantity_count

    def initialize(name, quantity, quantity_count, fields, message)
        @name = name
        @quantity = quantity
        @quantity_count = quantity_count
        @fields = fields
        @message = message
    end

    def ll_name
        @name
    end

    # Rust struct name.
    # We are combing the message name with the block name to avoid name clashes of blocks
    # with the same name but different specifications.
    def r_name
        "#{@message.name}_#{@name}"
    end

    # Field name.
    def f_name
        @name.underscore
    end
end

class Message
    attr_accessor :blocks, :id, :frequency
    # Both LL and Rust version are exactly the same.
    attr_accessor :name
    attr_accessor :comments
    attr_reader :encoding

    def initialize(fields)
        @name = fields[:name]
        @frequency = fields[:frequency]
        # note this is a string as fixed id messages have id of format 0xFFFF_FFFX.
        @id = fields[:id]
        @trust = fields[:trust]
        @encoding = fields[:encoding].downcase
        @blocks = fields[:blocks]
        @comments = fields[:comments]
    end

    def trusted
        @trust == "Trusted"
    end

    def message_num
        bs = [id_byte(3), id_byte(2), id_byte(1), id_byte(0)]
        "0x" + bs.map{|s| s[2..-1]}.join("")
    end

    # Returns a hexadecimal string (with '0x' prefix) of the n-th byte of the id.
    # Bytes are numbered from left to right in the spec, i.e. for High frequency messages
    # there is only byte 0. For Medium byte 0 is "0xff" while there is also byte 1 etc.
    def id_byte(n)
        @_full_id ||= @id.to_i.to_s(16).rjust(8, "0")
        full = @_full_id
        if @frequency == "High"
            if n == 0
                "0x" + full[6..7]
            else
                "0x00"
            end
        elsif @frequency == "Medium"
            if n == 0
                "0xff"
            elsif n == 1
                "0x"+full[6..7]
            else
                "0x00"
            end
        elsif @frequency == "Low"
            if n == 0 or n == 1
                "0xff"
            elsif n == 2
                "0x" + full[4..5]
            elsif n == 3
                "0x" + full[6..7]
            else
                "0x00"
            end
        elsif @frequency == "Fixed"
            full = @id[2..9]
            if 0 <= n and n <= 2
                "0xff"
            elsif n == 3
                "0x" + full[6..7]
            else
                "0x00"
            end
        else
            raise "invalid message frequency: #{message.frequency}"
        end
    end
end

