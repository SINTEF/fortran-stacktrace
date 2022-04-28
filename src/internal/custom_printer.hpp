// SPDX-FileCopyrightText: 2022 SINTEF Ocean
// SPDX-License-Identifier: MIT

#ifndef CUSTOM_PRINTER_H
#define CUSTOM_PRITER_H
#include "backward.hpp"
#include <filesystem>
#include <string>
#include <cctype>
#include <algorithm>

#define STRINGIFY(x) #x
#define TOSTRING(x) STRINGIFY(x)

using namespace backward;
namespace fs = std::filesystem;


std::string relativize(std::string filename) {
  auto path = fs::path(filename).lexically_normal();
  if (path.is_absolute()) {
    // Try to relativize filename relative to different source roots given as
    // compile definitions
#   ifdef SOURCE_ROOT1
      auto candidate1 = path.lexically_relative(TOSTRING(SOURCE_ROOT1)).string();
      if (candidate1.rfind("..", 0) != 0) {
        return candidate1;
      }
#   endif
#   ifdef SOURCE_ROOT2
      auto candidate2 = path.lexically_relative(TOSTRING(SOURCE_ROOT2)).string();
      if (candidate2.rfind("..", 0) != 0) {
        return candidate2;
      }
#   endif
#   ifdef SOURCE_ROOT3
      auto candidate3 = path.lexically_relative(TOSTRING(SOURCE_ROOT3)).string();
      if (candidate3.rfind("..", 0) != 0) {
        return candidate3;
      }
#   endif
  }
  return path.string();
}


std::string get_source_file(std::string filename) {
  // Intel Fortran on Windows seems to store relative filenames, which makes source code
  // lookup for snippets fail
  auto path = fs::path(filename);
  if (path.is_relative()) {
#   ifdef SOURCE_ROOT1
      auto candidate1 = (fs::path(TOSTRING(SOURCE_ROOT1)) / path).lexically_normal();
      if (fs::exists(candidate1)) {
        return candidate1.string();
      }
#   endif
#   ifdef SOURCE_ROOT2
      auto candidate2 = (fs::path(TOSTRING(SOURCE_ROOT2)) / path).lexically_normal();
      if (fs::exists(candidate2)) {
        return candidate2.string();
      }
#   endif
#   ifdef SOURCE_ROOT3
      auto candidate3 = (fs::path(TOSTRING(SOURCE_ROOT3)) / path).lexically_normal();
      if (fs::exists(candidate3)) {
        return candidate3.string();
      }
#   endif
  }
  return filename;
}


std::string str_tolower(std::string s) {
    std::transform(s.begin(), s.end(), s.begin(),
        [](unsigned char c){ return std::tolower(c); });
    return s;
}


std::string demangle_fortran(std::string filename, std::string procname) {
  auto ext = str_tolower(fs::path(filename).extension().string());
  // Typical and obscure Fortran file suffixes
  if (ext == ".f"  || ext == ".for" || ext == ".ftn" || ext == ".fpp" || ext == ".f90"
      || ext == ".pf" || ext == ".i" || ext == ".i90") {
#   if defined(_MSC_VER)
      // Intel Fortran on Windows: Try to demangle {MODULE_NAME}_mp_{PROC_NAME},
      // otherwise fallback to no demangling
      int idx = procname.find("_mp_");
      if (idx > 0) {
        return str_tolower(procname.substr(0, idx)) + "::"
            + str_tolower(procname.substr(idx + 4, std::string::npos));
      }
#   elif defined(__INTEL_COMPILER)
      // Intel Fortran on Linux: Try to demangle {module_name}_MP_{proc_name}_,
      // otherwise fallback to no demangling
      int idx = procname.find("_MP_");
      if (idx > 0) {
        int start = idx + 4;
        return procname.substr(0, idx) + "::"
            + procname.substr(start, procname.length() - start - 1);
      }
#   elif defined(__GNUC__)
      // GFortran on Linux: Try to demangle __{module_name}_MOD_{proc_name},
      // otherwise fallback to no demangling
      int idx = procname.rfind("_MOD_");
      if (idx > 0) {
        int start = idx + 5;
        return procname.substr(2, idx - 2) + "::"
            + procname.substr(start, std::string::npos);
      }
#   endif
  }
  return procname;
}


// Copy of bachward Printer with some modifications in order to relativize filenames
class CustomPrinter {
public:
  bool snippet;
  ColorMode::type color_mode;
  bool address;
  bool object;
  int inliner_context_size;
  int trace_context_size;

  CustomPrinter()
      : snippet(true), color_mode(ColorMode::automatic), address(false),
        object(false), inliner_context_size(5), trace_context_size(7) {}

  template <typename ST> FILE *print(ST &st, FILE *fp = stderr) {
    cfile_streambuf obuf(fp);
    std::ostream os(&obuf);
    Colorize colorize(os);
    colorize.activate(color_mode, fp);
    print_stacktrace(st, os, colorize);
    return fp;
  }

  template <typename ST> std::ostream &print(ST &st, std::ostream &os) {
    Colorize colorize(os);
    colorize.activate(color_mode);
    print_stacktrace(st, os, colorize);
    return os;
  }

  template <typename IT>
  FILE *print(IT begin, IT end, FILE *fp = stderr, size_t thread_id = 0) {
    cfile_streambuf obuf(fp);
    std::ostream os(&obuf);
    Colorize colorize(os);
    colorize.activate(color_mode, fp);
    print_stacktrace(begin, end, os, thread_id, colorize);
    return fp;
  }

  template <typename IT>
  std::ostream &print(IT begin, IT end, std::ostream &os,
                      size_t thread_id = 0) {
    Colorize colorize(os);
    colorize.activate(color_mode);
    print_stacktrace(begin, end, os, thread_id, colorize);
    return os;
  }

  TraceResolver const &resolver() const { return _resolver; }

private:
  TraceResolver _resolver;
  SnippetFactory _snippets;

  template <typename ST>
  void print_stacktrace(ST &st, std::ostream &os, Colorize &colorize) {
    print_header(os, st.thread_id());
    _resolver.load_stacktrace(st);
    for (size_t trace_idx = st.size(); trace_idx > 0; --trace_idx) {
      print_trace(os, _resolver.resolve(st[trace_idx - 1]), colorize);
    }
  }

  template <typename IT>
  void print_stacktrace(IT begin, IT end, std::ostream &os, size_t thread_id,
                        Colorize &colorize) {
    print_header(os, thread_id);
    for (; begin != end; ++begin) {
      print_trace(os, *begin, colorize);
    }
  }

  void print_header(std::ostream &os, size_t thread_id) {
    os << "Stack trace (most recent call last)";
    if (thread_id) {
      os << " in thread " << thread_id;
    }
    os << ":\n";
  }

  void print_trace(std::ostream &os, const ResolvedTrace &trace,
                   Colorize &colorize) {
    os << "#" << std::left << std::setw(2) << trace.idx << std::right;
    bool already_indented = true;

    if (!trace.source.filename.size() || object) {
      os << "   Object \"" << relativize(trace.object_filename) << "\", at " << trace.addr
         << ", in " << demangle_fortran(trace.object_filename, trace.object_function) << "\n";
      already_indented = false;
    }

    for (size_t inliner_idx = trace.inliners.size(); inliner_idx > 0;
         --inliner_idx) {
      if (!already_indented) {
        os << "   ";
      }
      const ResolvedTrace::SourceLoc &inliner_loc =
          trace.inliners[inliner_idx - 1];
      print_source_loc(os, " | ", inliner_loc);
      if (snippet) {
        print_snippet(os, "    | ", inliner_loc, colorize, Color::purple,
                      inliner_context_size);
      }
      already_indented = false;
    }

    if (trace.source.filename.size()) {
      if (!already_indented) {
        os << "   ";
      }
      print_source_loc(os, "   ", trace.source, trace.addr);
      if (snippet) {
        print_snippet(os, "      ", trace.source, colorize, Color::yellow,
                      trace_context_size);
      }
    }
  }

  void print_snippet(std::ostream &os, const char *indent,
                     const ResolvedTrace::SourceLoc &source_loc,
                     Colorize &colorize, Color::type color_code,
                     int context_size) {
    using namespace std;
    typedef SnippetFactory::lines_t lines_t;

    lines_t lines = _snippets.get_snippet(get_source_file(source_loc.filename), source_loc.line,
                                          static_cast<unsigned>(context_size));

    for (lines_t::const_iterator it = lines.begin(); it != lines.end(); ++it) {
      if (it->first == source_loc.line) {
        colorize.set_color(color_code);
        os << indent << ">";
      } else {
        os << indent << " ";
      }
      os << std::setw(4) << it->first << ": " << it->second << "\n";
      if (it->first == source_loc.line) {
        colorize.set_color(Color::reset);
      }
    }
  }

  void print_source_loc(std::ostream &os, const char *indent,
                        const ResolvedTrace::SourceLoc &source_loc,
                        void *addr = nullptr) {
    os << indent << "Source \"" << relativize(source_loc.filename) << "\", line "
       << source_loc.line << ", in " << demangle_fortran(source_loc.filename, source_loc.function);

    if (address && addr != nullptr) {
      os << " [" << addr << "]";
    }
    os << "\n";
  }
};

#endif