# A stable (partial) stdlib alternative for Zig

Don't expect much from this; it's not intended to be a full replacement for Zig's stdlib

---

- std.posix is being parted out (with the possibility of an outright removal); there will always be an implementation of it here (to be written)
    - It will be in the form it once was, when it was "at an awkward medium-level abstraction"
        - I, personally, felt that it was the perfect amount of abstraction, any less is just tedious to deal with C's lack of a concept of an error
        - In other words, it will just call something like (for example) std.os.linux.fork and convert any errors to a Zig error value (obviously, conditionally compiling for other platforms).
- Anything which is likely to be shared is protected by an atomic
- Intentionally simple
    - Some things use shared state (which's also protected by an atomic)
- After this repo is set to public, nothing will ever be removed (I promise)
- Any and all uses of Zig's stdlib are clearly marked, explained, and have information about replacement (via a comment at the top of the file using it)
    - Anything which does use something in Zig's stdlib that could break (or just be removed entirely) will likely get an implementation here in the future
    - It should be noted that if I feel that something is probably too load-bearing (for Zig's stdlib) to be removed, it may be used here significantly longer than it otherwise would
