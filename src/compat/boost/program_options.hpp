#ifndef OSMIUMR_COMPAT_BOOST_PROGRAM_OPTIONS_HPP
#define OSMIUMR_COMPAT_BOOST_PROGRAM_OPTIONS_HPP

// osmiumr note: this is NOT a copy of any part of Boost. It is a small,
// independently written, header-only stand-in for the specific subset of
// the boost::program_options API that osmium-tool's vendored
// command_*.cpp setup() methods use (see ../../../plan.md for why).
//
// Real boost::program_options has a compiled (non-header-only)
// implementation upstream, so pulling in its headers alone -- from a
// system install or from the BH package -- is not enough to link; either
// the system library or a from-source build of Boost's own
// program_options .cpp files would be needed. This header avoids that
// entirely by reimplementing just the pieces actually used, so that
// osmium-tool's own Command::setup() bodies compile completely unchanged
// (they only ever do `#include <boost/program_options.hpp>` and
// `namespace po = boost::program_options;`).
//
// This file is deliberately placed on the include path ahead of any real
// boost so it satisfies that #include. It is not a general-purpose
// program_options replacement: every vendored setup() builds its
// std::vector<std::string> "arguments" from osmiumr's own R wrapper
// functions, never from a raw shell command line, so only a reduced
// grammar is supported:
//   - long options as two separate tokens: "--name" or "--name" "value"
//     (no "--name=value" attachment)
//   - matching short options: "-x" or "-x" "value" (single character,
//     no bundling of multiple short flags in one token)
//   - repeating a multi-value option's flag accumulates values, e.g.
//     "--object-type" "node" "--object-type" "way"
//   - "--" ends option parsing; everything after is positional
//   - positional tokens are distributed across positional_options_
//     description entries in registration order, honoring each entry's
//     max_count (-1 = consume all remaining tokens)
//
// Only the two option value types osmium-tool's commands actually use are
// supported: std::string and std::vector<std::string>.

#include <map>
#include <ostream>
#include <stdexcept>
#include <string>
#include <utility>
#include <vector>

namespace boost {
namespace program_options {

/// Thrown for anything that would be a command-line syntax/usage error:
/// unrecognised option, option missing its required value, or an
/// unexpected positional argument. Mirrors boost::program_options::error
/// closely enough that code catching that type (osmiumr's r_bridge.cpp)
/// still catches parsing problems here.
class error : public std::logic_error {
public:
    explicit error(const std::string& what_arg) :
        std::logic_error(what_arg) {
    }
};

namespace detail {

enum class value_kind {
    flag,
    string,
    string_vector
};

struct option_spec {
    std::string long_name;
    char short_name = '\0';
    std::string description;
    value_kind kind = value_kind::flag;
    bool has_default = false;
    std::string default_value;
};

inline option_spec make_spec(const std::string& name_spec,
                              const std::string& description,
                              value_kind kind,
                              bool has_default,
                              const std::string& default_value) {
    option_spec spec;
    spec.description = description;
    spec.kind = kind;
    spec.has_default = has_default;
    spec.default_value = default_value;

    const auto comma = name_spec.find(',');
    if (comma == std::string::npos) {
        spec.long_name = name_spec;
    } else {
        spec.long_name = name_spec.substr(0, comma);
        if (comma + 1 < name_spec.size()) {
            spec.short_name = name_spec[comma + 1];
        }
    }
    return spec;
}

} // namespace detail

/// Result of po::value<T>(). Real boost returns a heap-allocated
/// typed_value<T>* here (hence callers chaining with `->`), so this does
/// the same rather than changing every vendored call site to `.`.
class value_spec {
public:
    explicit value_spec(detail::value_kind kind) :
        kind_(kind) {
    }

    value_spec* default_value(const std::string& v) {
        has_default_ = true;
        default_value_ = v;
        return this;
    }

    detail::value_kind kind() const noexcept {
        return kind_;
    }

    bool has_default() const noexcept {
        return has_default_;
    }

    const std::string& default_str() const noexcept {
        return default_value_;
    }

private:
    detail::value_kind kind_;
    bool has_default_ = false;
    std::string default_value_;
};

template <typename T>
value_spec* value();

template <>
inline value_spec* value<std::string>() {
    return new value_spec(detail::value_kind::string); // NOLINT(cppcoreguidelines-owning-memory)
}

template <>
inline value_spec* value<std::vector<std::string>>() {
    return new value_spec(detail::value_kind::string_vector); // NOLINT(cppcoreguidelines-owning-memory)
}

class options_description;

/// Returned by options_description::add_options(); operator() is chained
/// once per option, e.g. `desc.add_options() ("a,b", "desc") ("c", ...);`.
class options_description_easy_init {
public:
    explicit options_description_easy_init(options_description* owner) :
        owner_(owner) {
    }

    // Flag option, e.g. ("verbose,v", "Set verbose mode")
    options_description_easy_init& operator()(const char* name_spec, const char* description);

    // Typed option, e.g. ("output,o", po::value<std::string>(), "Output file")
    options_description_easy_init& operator()(const char* name_spec, value_spec* value, const char* description);

private:
    options_description* owner_;
};

class options_description {
public:
    options_description() = default;

    explicit options_description(const std::string& caption) :
        caption_(caption) {
    }

    options_description_easy_init add_options() {
        return options_description_easy_init(this);
    }

    options_description& add(const options_description& other) {
        specs_.insert(specs_.end(), other.specs_.begin(), other.specs_.end());
        return *this;
    }

    void add_spec(detail::option_spec spec) {
        specs_.push_back(std::move(spec));
    }

    const std::vector<detail::option_spec>& specs() const noexcept {
        return specs_;
    }

    const std::string& caption() const noexcept {
        return caption_;
    }

private:
    std::string caption_;
    std::vector<detail::option_spec> specs_;
};

inline options_description_easy_init& options_description_easy_init::operator()(const char* name_spec, const char* description) {
    owner_->add_spec(detail::make_spec(name_spec, description, detail::value_kind::flag, false, ""));
    return *this;
}

inline options_description_easy_init& options_description_easy_init::operator()(const char* name_spec, value_spec* value, const char* description) {
    owner_->add_spec(detail::make_spec(name_spec, description, value->kind(),
                                        value->has_default(), value->default_str()));
    return *this;
}

inline std::ostream& operator<<(std::ostream& os, const options_description& desc) {
    if (!desc.caption().empty()) {
        os << desc.caption() << ":\n";
    }
    for (const auto& spec : desc.specs()) {
        os << "  --" << spec.long_name;
        if (spec.short_name != '\0') {
            os << " [-" << spec.short_name << "]";
        }
        os << "\n      " << spec.description << "\n";
    }
    return os;
}

class positional_options_description {
public:
    positional_options_description& add(const char* name, int max_count) {
        entries_.emplace_back(name, max_count);
        return *this;
    }

    const std::vector<std::pair<std::string, int>>& entries() const noexcept {
        return entries_;
    }

private:
    std::vector<std::pair<std::string, int>> entries_;
};

/// Holds one option's parsed value. Kind-tagged rather than templated so
/// it can live in a homogeneous map inside variables_map.
class variable_value {
public:
    variable_value() = default;

    explicit variable_value(std::string s) :
        kind_(detail::value_kind::string),
        str_(std::move(s)) {
    }

    explicit variable_value(std::vector<std::string> v) :
        kind_(detail::value_kind::string_vector),
        vec_(std::move(v)) {
    }

    void append(const std::string& s) {
        kind_ = detail::value_kind::string_vector;
        vec_.push_back(s);
    }

    template <typename T>
    const T& as() const;

private:
    detail::value_kind kind_ = detail::value_kind::flag;
    std::string str_;
    std::vector<std::string> vec_;
};

template <>
inline const std::string& variable_value::as<std::string>() const {
    return str_;
}

template <>
inline const std::vector<std::string>& variable_value::as<std::vector<std::string>>() const {
    return vec_;
}

class variables_map {
public:
    std::size_t count(const std::string& name) const {
        return values_.count(name);
    }

    const variable_value& operator[](const std::string& name) const {
        static const variable_value empty{};
        const auto it = values_.find(name);
        return it == values_.end() ? empty : it->second;
    }

    void set(const std::string& name, variable_value value) {
        values_[name] = std::move(value);
    }

private:
    std::map<std::string, variable_value> values_;
};

/// What command_line_parser::run() returns: the raw assignments parsed
/// from argv-like tokens, plus the option specs they were parsed against
/// (so store() can fill in defaults for options the user didn't supply).
class parsed_options {
public:
    std::map<std::string, variable_value> assigned;
    std::vector<detail::option_spec> specs;
};

namespace detail {

inline const option_spec* find_by_long(const std::vector<option_spec>& specs, const std::string& name) {
    for (const auto& spec : specs) {
        if (spec.long_name == name) {
            return &spec;
        }
    }
    return nullptr;
}

inline const option_spec* find_by_short(const std::vector<option_spec>& specs, char c) {
    for (const auto& spec : specs) {
        if (spec.short_name == c) {
            return &spec;
        }
    }
    return nullptr;
}

inline parsed_options parse(const std::vector<std::string>& args,
                             const std::vector<option_spec>& specs,
                             const positional_options_description& positional) {
    parsed_options result;
    result.specs = specs;

    std::vector<std::string> positional_tokens;
    bool options_ended = false;

    for (std::size_t i = 0; i < args.size(); ++i) {
        const std::string& tok = args[i];

        if (!options_ended && tok == "--") {
            options_ended = true;
            continue;
        }

        if (!options_ended && tok.size() >= 2 && tok[0] == '-') {
            const option_spec* spec = nullptr;
            if (tok.size() >= 3 && tok[1] == '-') {
                spec = find_by_long(specs, tok.substr(2));
            } else {
                spec = find_by_short(specs, tok[1]);
            }
            if (!spec) {
                throw error{"unrecognised option '" + tok + "'"};
            }

            if (spec->kind == value_kind::flag) {
                result.assigned[spec->long_name] = variable_value{std::string{}};
            } else {
                if (i + 1 >= args.size()) {
                    throw error{"option '" + tok + "' requires a value"};
                }
                const std::string& val = args[++i];
                if (spec->kind == value_kind::string) {
                    result.assigned[spec->long_name] = variable_value{val};
                } else {
                    auto it = result.assigned.find(spec->long_name);
                    if (it == result.assigned.end()) {
                        result.assigned[spec->long_name] = variable_value{std::vector<std::string>{val}};
                    } else {
                        it->second.append(val);
                    }
                }
            }
            continue;
        }

        positional_tokens.push_back(tok);
    }

    std::size_t idx = 0;
    for (const auto& entry : positional.entries()) {
        const std::string& name = entry.first;
        const int max_count = entry.second;
        const option_spec* spec = find_by_long(specs, name);

        std::vector<std::string> vals;
        if (max_count < 0) {
            vals.assign(positional_tokens.begin() + static_cast<std::ptrdiff_t>(idx), positional_tokens.end());
            idx = positional_tokens.size();
        } else {
            for (int c = 0; c < max_count && idx < positional_tokens.size(); ++c, ++idx) {
                vals.push_back(positional_tokens[idx]);
            }
        }

        if (vals.empty()) {
            continue;
        }
        if (spec && spec->kind == value_kind::string_vector) {
            result.assigned[name] = variable_value{vals};
        } else {
            result.assigned[name] = variable_value{vals.front()};
        }
    }

    if (idx < positional_tokens.size()) {
        throw error{"too many positional arguments (unexpected '" + positional_tokens[idx] + "')"};
    }

    return result;
}

} // namespace detail

class command_line_parser {
public:
    explicit command_line_parser(const std::vector<std::string>& args) :
        args_(args) {
    }

    command_line_parser& options(const options_description& desc) {
        specs_ = desc.specs();
        return *this;
    }

    command_line_parser& positional(const positional_options_description& positional) {
        positional_ = positional;
        return *this;
    }

    parsed_options run() const {
        return detail::parse(args_, specs_, positional_);
    }

private:
    std::vector<std::string> args_;
    std::vector<detail::option_spec> specs_;
    positional_options_description positional_;
};

inline void store(const parsed_options& parsed, variables_map& vm) {
    for (const auto& kv : parsed.assigned) {
        vm.set(kv.first, kv.second);
    }
    for (const auto& spec : parsed.specs) {
        if (spec.kind != detail::value_kind::flag && spec.has_default &&
            parsed.assigned.find(spec.long_name) == parsed.assigned.end()) {
            vm.set(spec.long_name, variable_value{spec.default_value});
        }
    }
}

/// No-op: nothing in the vendored code registers po::notifier() callbacks
/// or ->required() constraints, which are the only things real boost's
/// notify() would need to act on.
inline void notify(variables_map&) {
}

} // namespace program_options
} // namespace boost

#endif // OSMIUMR_COMPAT_BOOST_PROGRAM_OPTIONS_HPP
