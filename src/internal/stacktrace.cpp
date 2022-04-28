// SPDX-FileCopyrightText: 2022 SINTEF Ocean
// SPDX-License-Identifier: MIT

// Backward gives a few extra stack frames depending on optimization level.
// By setting optimization using pragmas here we can decide on how many to skip
#if defined(_WIN32)
    // Windows (both MSVC and the Intel C++ compiler will define _MSC_VER)
    // The version checks below might be overkill since the -std=c++17 flag is used.
#   if defined(_MSC_VER) && _MSC_VER > 1914
        // MSVC 15.6 definitely not supported. Even newer versions might be required,
        // but currently not tested.
#       pragma optimize("", off)
#       define SKIP_OFFSET 3
#   elif defined(__GNUC__)
#       error "Compiler/OS combination currently not supported"
#   else
#       error "Compiler/OS combination currently not supported"
#   endif
#elif defined(__linux__)
    // Linux
    // IMPORTANT: Intel C++ also defines __GNUC__!!
    //            The order of these check are crucial
#   if defined(__INTEL_COMPILER) && __INTEL_COMPILER > 2016
        // Intel 2016 definitely not supported. Even newer versions might be required,
        // but currently not tested.
#       pragma optimize("", off)
#       define SKIP_OFFSET 4
#   elif defined(__GNUC__)
#       pragma GCC optimize ("O2")
#       define SKIP_OFFSET 2
#   else
#       error "Compiler/OS combination currently not supported"
#   endif
#endif

#include <string>
#include <sstream>
#include <memory>
#include "backward.hpp"
#include "custom_printer.hpp"


// Implemented in stacktrace_interface.f90
extern "C" void stacktrace__set_f_string(void*, const char*);

extern "C"
{
    void stacktrace__destruct(std::shared_ptr<backward::StackTrace>* st)
    {
        delete st;
    }


    std::shared_ptr<backward::StackTrace>* stacktrace__assign_from(
        std::shared_ptr<backward::StackTrace>* st)
    {
        auto new_st = new std::shared_ptr<backward::StackTrace>();
        *new_st = *st;
        return new_st;
    }


    std::shared_ptr<backward::StackTrace>* stacktrace__load_here(
        int max_depth,
        int num_skip)
    {
#       ifdef _WIN32
            // Windows only workaround
            // See https://github.com/bombela/backward-cpp/issues/206
            backward::TraceResolver this_is_a_workaround;
#       endif
        auto st_raw = new backward::StackTrace();
        auto st = new std::shared_ptr<backward::StackTrace>(st_raw);
        (*st)->load_here(max_depth);
        (*st)->skip_n_firsts(num_skip + SKIP_OFFSET);
        return st;
    }


    void stacktrace__to_chars(std::shared_ptr<backward::StackTrace>* st,
        bool snippet,
        void* fstr)
    {
        std::ostringstream stream;
        CustomPrinter p;
        p.snippet = snippet;
        p.print(**st, stream);
        std::string str = stream.str();
        stacktrace__set_f_string(fstr, str.data());
    }
}