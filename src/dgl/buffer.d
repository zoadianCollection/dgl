/*
 *             Copyright Andrej Mitrovic 2013.
 *  Distributed under the Boost Software License, Version 1.0.
 *     (See accompanying file LICENSE_1_0.txt or copy at
 *           http://www.boost.org/LICENSE_1_0.txt)
 */
module dgl.buffer;

import std.stdio;
import std.typecons;

import minilib.core.array;
import minilib.core.test;

import derelict.opengl3.gl3;

import dgl.attribute;
import dgl.test.util;

/// All possible OpenGL usage hints
enum UsageHint
{
    /// sentinel
    invalid,

    ///
    staticDraw = GL_STATIC_DRAW,

    ///
    dynamicDraw = GL_DYNAMIC_DRAW,

    ///
    streamDraw = GL_STREAM_DRAW,
}

/**
    The OpenGL buffer type.

    This is a refcounted type which can be freely copied around.
    Once the reference count reaches 0 the underlying OpenGL buffer
    will be deleted.

    The $(D release) method can be called for manual release of OpenGL resources.
*/
struct GLBuffer
{
    /**
        Create and initialize an OpenGL buffer with the
        contents of $(D buffer) and the buffer hint $(D usageHint).
    */
    this(T)(T[] buffer, UsageHint usageHint)
    {
        _data = Data(buffer, usageHint);
    }

    /**
        Write the $(D buffer) data to this buffer, at byte offset $(D byteOffset).
        This will overwrite the data that was already in the buffer.
    */
    void write(T)(T[] buffer, ptrdiff_t byteOffset = 0)
    {
        _data.write(buffer, byteOffset);
    }

    /** Bind this buffer to an attribute. */
    void bind(Attribute attribute, int size, GLenum type, bool normalized, int stride, int offset)
    {
        _data.bind(attribute, size, type, cast(GLboolean)normalized, stride, offset);
    }

    /** Unbind this buffer. */
    void unbind()
    {
        _data.unbind();
    }

    /** Explicitly delete the OpenGL buffer. */
    void release()
    {
        _data.release();
    }

private:

    alias Data = RefCounted!(GLBufferImpl, RefCountedAutoInitialize.no);
    Data _data;
}

private struct GLBufferImpl
{
    this(T)(T[] buffer, UsageHint usageHint)
    {
        require(usageHint.isValidEnum, "Usage hint is uninitialized.");

        verify!glGenBuffers(bufferCount, &_bufferID);
        verify!glBindBuffer(GL_ARRAY_BUFFER, _bufferID);
        verify!glBufferData(GL_ARRAY_BUFFER, buffer.memSizeOf, buffer.ptr, cast(GLenum)usageHint);
        verify!glBindBuffer(GL_ARRAY_BUFFER, nullBufferID);
    }

    ~this()
    {
        release();
    }

    void write(T)(T[] buffer, ptrdiff_t byteOffset)
    {
        verify!glBindBuffer(GL_ARRAY_BUFFER, _bufferID);
        verify!glBufferSubData(GL_ARRAY_BUFFER, byteOffset, buffer.memSizeOf, buffer.ptr);
        verify!glBindBuffer(GL_ARRAY_BUFFER, nullBufferID);
    }

    void bind(Attribute attribute, GLint size, GLenum type, GLboolean normalized, GLsizei stride, GLsizei offset)
    {
        verify!glBindBuffer(GL_ARRAY_BUFFER, _bufferID);
        verify!glVertexAttribPointer(attribute._attributeID, size, type, normalized, stride, cast(void*)offset);
    }

    void unbind()
    {
        verify!glBindBuffer(GL_ARRAY_BUFFER, nullBufferID);
    }

    void release()
    {
        if (_bufferID != invalidBufferID)
        {
            verify!glDeleteBuffers(bufferCount, &_bufferID);
            _bufferID = invalidBufferID;
        }
    }

    /// Should never perform copy
    @disable this(this);

    /// Should never perform assign
    @disable void opAssign(typeof(this));

    /* Buffer data. */
    GLuint _bufferID = invalidBufferID;

    private enum bufferCount = 1;

    // sentinel
    private enum invalidBufferID = -1;

    // used for unbinding
    private enum nullBufferID = 0;
}
