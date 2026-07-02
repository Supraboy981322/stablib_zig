const module = @import("../module.zig");

const mem = module.mem;
const meta = module.meta;
const testing = module.testing;

const contains = mem.contains;
const expect = testing.expect;
const ints = meta.enumInts;

pub const whitespace:[]const u8 = &.{
    Character.space,         //' '
    Control.horizontal_tab,  //'\t'
    Control.carriage_return, //'\r'
    Control.line_feed,       //'\n'
    Control.vertical_tab,    //'\v'
    Control.form_feed        //'\f'
};
pub const digits = blk: {
    var buf = [_]u8{undefined} ** 10;
    for ('0'..'9'+1, 0..) |c, i| buf[i] = c;
    break :blk buf;
};
pub const lowercase = blk: {
    var buf = [_]u8{undefined} ** 26;
    for ('a'..'z'+1, 0..) |c, i| buf[i] = c;
    break :blk buf;
};
pub const uppercase = blk: {
    var buf = [_]u8{undefined} ** 26;
    for ('A'..'Z'+1, 0..) |c, i| buf[i] = c;
    break :blk buf;
};
pub const letters = lowercase ++ uppercase;
pub const characters = ints(Character);
pub const control_chars = ints(Control);


pub const Control = enum(u8) {
    nul = 0o000,
    start_of_heading = 0o001,
    start_of_text = 0o002,
    end_of_text = 0o003,
    end_of_transmission = 0o004,
    enquiry = 0o005,
    acknowledge = 0o006,
    bell = 0o007,
    backspace = 0o010,
    horizontal_tab = 0o011,
    line_feed = 0o012,
    vertical_tab = 0o013,
    form_feed = 0o014,
    carriage_return = 0o015,
    shift_out = 0o016,
    shift_in = 0o017,
    data_link_escape = 0o020,
    dev_ctrl_1 = 0o021,
    dev_ctrl_2 = 0o022,
    dev_ctrl_3 = 0o023,
    dev_ctrl_4 = 0o024,
    negative_acknowledge = 0o025,
    synchronous_idle = 0o026,
    end_of_transmission_block = 0o027,
    cancel = 0o030,
    end_of_medium = 0o031,
    substitute = 0o032,
    escape = 0o033,
    file_separator = 0o034,
    group_separator = 0o035,
    record_separator = 0o036,
    unit_separator = 0o037,
    delete = 0o177,

    pub const newline = Control.line_feed;
    pub const tab = Control.horizontal_tab;
};

pub const Character = enum(u8) {
    space = ' ',
    exclamation_mark = '!',
    quotation_mark = '"',
    pound_sign = '#',
    dollar_sign = '$',
    percent_sign = '%',
    ampersand = '&',
    apostrophe = '\'',
    left_parenthesis = '(',
    right_parenthesis = ')',
    asterisk = '*',
    plus_sign = '+',
    comma = ',',
    hyphen = '-',
    period = '.',
    forward_slash = '/',
    digit_0 = '0',
    digit_1 = '1',
    digit_2 = '2',
    digit_3 = '3',
    digit_4 = '4',
    digit_5 = '5',
    digit_6 = '6',
    digit_7 = '7',
    digit_8 = '8',
    digit_9 = '9',
    colon = ':',
    semicolon = ';',
    less_than = '<',
    equal_sign = '=',
    greater_than = '>',
    question_mark = '?',
    at_sign = '@',
    uppercase_letter_a = 'A',
    uppercase_letter_b = 'B',
    uppercase_letter_c = 'C',
    uppercase_letter_d = 'D',
    uppercase_letter_e = 'E',
    uppercase_letter_f = 'F',
    uppercase_letter_g = 'G',
    uppercase_letter_h = 'H',
    uppercase_letter_i = 'I',
    uppercase_letter_j = 'J',
    uppercase_letter_k = 'K',
    uppercase_letter_l = 'L',
    uppercase_letter_m = 'M',
    uppercase_letter_n = 'N',
    uppercase_letter_o = 'O',
    uppercase_letter_p = 'P',
    uppercase_letter_q = 'Q',
    uppercase_letter_r = 'R',
    uppercase_letter_s = 'S',
    uppercase_letter_t = 'T',
    uppercase_letter_u = 'U',
    uppercase_letter_v = 'V',
    uppercase_letter_w = 'W',
    uppercase_letter_x = 'X',
    uppercase_letter_y = 'Y',
    uppercase_letter_z = 'Z',
    left_square_bracket = '[',
    backslash = '\\',
    right_square_bracket = ']',
    caret = '^',
    grave_accent = '`',
    lowercase_letter_a = 'a',
    lowercase_letter_b = 'b',
    lowercase_letter_c = 'c',
    lowercase_letter_d = 'd',
    lowercase_letter_e = 'e',
    lowercase_letter_f = 'f',
    lowercase_letter_g = 'g',
    lowercase_letter_h = 'h',
    lowercase_letter_i = 'i',
    lowercase_letter_j = 'j',
    lowercase_letter_k = 'k',
    lowercase_letter_l = 'l',
    lowercase_letter_m = 'm',
    lowercase_letter_n = 'n',
    lowercase_letter_o = 'o',
    lowercase_letter_p = 'p',
    lowercase_letter_q = 'q',
    lowercase_letter_r = 'r',
    lowercase_letter_s = 's',
    lowercase_letter_t = 't',
    lowercase_letter_u = 'u',
    lowercase_letter_v = 'v',
    lowercase_letter_w = 'w',
    lowercase_letter_x = 'x',
    lowercase_letter_y = 'y',
    lowercase_letter_z = 'z',
    left_curly_brace = '{',
    vertical_bar = '|',
    right_curly_brace = '}',
    tilde = '~',
    
    pub const pipe = Character.vertical_bar;
};



pub inline fn isDigit(b:u8) bool {
    return b >= '0' and b <= '9';
}
pub inline fn isLowercase(b:u8) bool {
    return b >= 'a' and b <= 'z';
}
pub inline fn isUppercase(b:u8) bool {
    return b >= 'A' and b <= 'Z';
}
pub inline fn isAlpha(b:u8) bool {
    return isLowercase(b) or isUppercase(b);
}
pub inline fn isWhitespace(b:u8) bool {
    return contains(u8, whitespace, b);
}
pub inline fn isAlphanumeric(b:u8) bool {
    return isDigit(b) or isAlpha(b);
}
pub fn isControl(b:u8) bool {
    return contains(u8, &ints(Control), b);
}
pub fn isCharacter(b:u8) bool {
    return contains(u8, &ints(Character), b);
}
pub inline fn isAscii(b:u8) bool {
    return isControl(b) or isCharacter(b);
}


test "basic" {
    const chars = ints(Character);
    for (chars) |c| try expect(isCharacter(c) and !isControl(c));

    const ctrls = ints(Control);
    for (ctrls) |c| try expect(!isCharacter(c) and isControl(c));

    const ascii = chars ++ ctrls;
    for (ascii) |c| try expect(isAscii(c) and (isCharacter(c) != isControl(c)));
}
