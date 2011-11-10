#include "ruby.h"
#include <stdint.h>

VALUE rb_module_randseq = Qnil;
VALUE rb_class_letterseq = Qnil;
VALUE rb_class_byteseq = Qnil;

/*
 * Code shared by RandSeq::Letters and RandSeq::Bytes.
 */ 
typedef struct {
    uint8_t*    buf;
    size_t      size;
    uint64_t    next;
} rand_seq_t;

static void
rand_seq_t_free(void *_self)
{
    rand_seq_t *self = (rand_seq_t*) _self;

    if (self->buf != NULL) {
        free(self->buf);
    }

    free(self);
}

VALUE
rb_randseq_new(VALUE klass, VALUE rb_size, VALUE rb_seed)
{
    VALUE rb_self;
    rand_seq_t *self;

    self = ALLOC(rand_seq_t);
    self->size = NUM2ULONG(rb_size);

    /* We need to allocate extra space; up to 12 bytes in the case of
     * Letters, 8 in the case of Bytes. Ah, hell, let's round it up to
     * 16 bytes.
     */
    self->buf = ALLOC_N(uint8_t, self->size + 16);

    if (rb_seed = Qnil) {
        /* Initialized with a couple rounds of the generator. */
        self->next = 0x490c734ad1ccf6e9;
    }
    else {
        self->next = NUM2ULONG(rb_seed);
    }
    
    rb_self = Data_Wrap_Struct(klass, NULL, rand_seq_t_free, self);

    rb_obj_call_init(rb_self, 0, NULL);

    return rb_self;
}

/*
 * RandSeq::Letters.next
 */ 
VALUE
rb_letterseq_next(VALUE rb_self)
{
    const uint64_t a = 1664525;
    const uint64_t c = 1013904223;
    rand_seq_t *self;
    unsigned long size;
    uint8_t *buf;
    uint64_t next;
    size_t i, j;

    Data_Get_Struct(rb_self, rand_seq_t, self);

    /* Get these local so we're not deref'ing self inside loop. */
    size = self->size;
    buf = self->buf;
    next = self->next;

    /* Fill in buf 12 letters at a time. Since we're only using
     * lowercase letters, but generating 64 bits of randomness at a
     * time, we can use 5 bits for each letter. Buffer is already
     * over-size to accomodate extra letters at the end. Algorithm and
     * constants borrowed from Numerical Recipes in C (2nd ed),
     * section 7.1.
     */
    for (i = 0; i < size; i += 12) {
        next = next * a + c;

        *buf++ = ((next & 0x00000000000001f) >> 00) % ('z' - 'a' + 1) + 'a';
        *buf++ = ((next & 0x0000000000003e0) >> 05) % ('z' - 'a' + 1) + 'a';
        *buf++ = ((next & 0x000000000007c00) >> 10) % ('z' - 'a' + 1) + 'a';
        *buf++ = ((next & 0x0000000000f8000) >> 15) % ('z' - 'a' + 1) + 'a';
        *buf++ = ((next & 0x000000001f00000) >> 20) % ('z' - 'a' + 1) + 'a';
        *buf++ = ((next & 0x00000003e000000) >> 25) % ('z' - 'a' + 1) + 'a';
        *buf++ = ((next & 0x0000007c0000000) >> 30) % ('z' - 'a' + 1) + 'a';
        *buf++ = ((next & 0x00000f800000000) >> 35) % ('z' - 'a' + 1) + 'a';
        *buf++ = ((next & 0x0001f0000000000) >> 40) % ('z' - 'a' + 1) + 'a';
        *buf++ = ((next & 0x003e00000000000) >> 45) % ('z' - 'a' + 1) + 'a';
        *buf++ = ((next & 0x07c000000000000) >> 50) % ('z' - 'a' + 1) + 'a';
        *buf++ = ((next & 0xf80000000000000) >> 55) % ('z' - 'a' + 1) + 'a';
    }

    /* Chop down to actual number of letters requested. */
    self->buf[size] = 0;
    self->next = next;
    
    return rb_str_new((char*) self->buf, size);
}

/*
 * RandSeq::Bytes.next
 */ 
VALUE
rb_byteseq_next(VALUE rb_self)
{
    const uint64_t a = 1664525;
    const uint64_t c = 1013904223;
    rand_seq_t *self;
    unsigned long size;
    uint8_t *buf;
    uint64_t next;
    size_t i, j;

    Data_Get_Struct(rb_self, rand_seq_t, self);

    /* Get these local so we're not deref'ing self inside loop. */
    size = self->size;
    buf = self->buf;
    next = self->next;

    /* Fill in buf 64 bits at a time. Algorithm and constants
     * borrowed from Numerical Recipes in C (2nd ed), section 7.1.
     */
    for (i = 0; i < size; i += sizeof(uint64_t)) {
        next = next * a + c;
        
        *((uint64_t*) buf) = next;
        buf += sizeof(uint64_t);
    }

    self->buf[size] = 0;
    self->next = next;
    
    return rb_str_new((char*) self->buf, size);
}

void Init_randseq()
{
    rb_module_randseq = rb_define_module("RandSeq");
    rb_class_letterseq = rb_define_class_under(rb_module_randseq, "Letters", rb_cObject);
    rb_define_singleton_method(rb_class_letterseq, "new", rb_randseq_new, 2);
    rb_define_method(rb_class_letterseq, "next", rb_letterseq_next, 0);

    rb_class_byteseq = rb_define_class_under(rb_module_randseq, "Bytes", rb_cObject);
    rb_define_singleton_method(rb_class_byteseq, "new", rb_randseq_new, 2);
    rb_define_method(rb_class_byteseq, "next", rb_byteseq_next, 0);
}
