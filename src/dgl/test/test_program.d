/*
 *             Copyright Andrej Mitrovic 2013.
 *  Distributed under the Boost Software License, Version 1.0.
 *     (See accompanying file LICENSE_1_0.txt or copy at
 *           http://www.boost.org/LICENSE_1_0.txt)
 */
module dgl.test.test_program;

/**
    Test dgl.program.
*/

import core.exception;
import std.exception;
import std.file;

import minilib.core.test;

import derelict.opengl3.gl3;

import dgl.program;
import dgl.shader;
import dgl.test.util;

unittest
{
    auto shader1 = Shader(ShaderType.vertex, testShaders[0].vertex.readText);
    auto shader2 = Shader(ShaderType.fragment, testShaders[0].fragment.readText);
    auto program = Program(shader1, shader2);

    auto uniform = program.getUniform("offset");

    program.bind();

    // the uniform can only be set while the program is in use
    program.setUniform2f(uniform, 1.0, 2.0);

    program.unbind();
}
