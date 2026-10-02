# JSON to XML Converter

![Language: C](https://img.shields.io/badge/language-C-blue.svg)
![Tools: Flex & Bison](https://img.shields.io/badge/tools-Flex%20%26%20Bison-orange.svg)
![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)

A command-line tool that converts JSON documents into XML, built in C with **Flex** (lexical analysis) and **Bison** (syntax analysis).

## Table of Contents

- [Background](#background)
- [Features](#features)
- [How It Works](#how-it-works)
- [Install](#install)
- [Usage](#usage)
- [Testing](#testing)
- [Project Structure](#project-structure)
- [Limitations](#limitations)
- [Roadmap](#roadmap)
- [Author](#author)
- [License](#license)

## Background

This project was developed for the **Formal Languages and Translators** course at the Faculty of Automation and Computer Science. Its goal is to apply compiler-construction concepts (tokens, context-free grammars, syntax-directed translation) to a practical problem: translating one structured data format into another.

The full project report (in Romanian) is available in [`Documentatie_LFT.pdf`](Documentatie_LFT.pdf).

## Features

- Converts JSON objects, including nested objects and arrays, into XML
- Supports strings, integers, decimal numbers, `true`, `false` and `null`
- Reports syntax errors with the exact **line and column**
- Never leaves stale output: if the input is invalid, no XML file is written
- Frees all allocated memory, including when parsing fails

## How It Works

The conversion runs in two stages, each generated from its own specification file:

```
input.json ──► Lexer (Flex) ──► tokens ──► Parser (Bison) ──► output.xml
               proiect.l                   proiect.y
```

**1. Lexical analysis — `src/proiect.l`**

The lexer reads the input character by character and groups it into tokens:

| Token | Matches |
|---|---|
| `{` `}` `[` `]` `:` `,` | JSON delimiters |
| `STRING` | quoted text, numbers, `true`, `false`, `null` |
| `INVALID` | any unexpected character |
| `UNTERMINATED` | a string that is not closed before the end of the line |

It also tracks the line and column of every token, so errors can point to their exact position.

**2. Syntax analysis and translation — `src/proiect.y`**

The parser checks the token sequence against the JSON grammar:

```
json           → object
object         → { pair_list }
pair_list      → pair | pair , pair_list
pair           → STRING : value
value          → STRING | object | array
array          → [ array_elements ]
array_elements → value | value , array_elements
```

Each grammar rule has an action that builds the corresponding XML fragment:

| JSON | XML |
|---|---|
| whole document | `<root> ... </root>` |
| `"key": value` | `<key>value</key>` |
| array element | `<item>value</item>` |

## Install

### Requirements

- A C compiler (GCC or Clang)
- Flex
- Bison

On Debian, Ubuntu or Linux Mint:

```bash
sudo apt install build-essential flex bison
```

### Build

```bash
git clone https://github.com/tavim26/json-to-xml-converter.git
cd json-to-xml-converter/src
bison -d proiect.y      # generates proiect.tab.c and proiect.tab.h
flex proiect.l          # generates lex.yy.c
gcc -Wall -Wextra proiect.tab.c lex.yy.c -o json2xml
```

> **Windows:** the same steps work with [WinFlexBison](https://github.com/lexxmark/winflexbison), using `win_bison` and `win_flex` instead of `bison` and `flex`.

## Usage

The program reads JSON from standard input and writes the result to `output.xml` in the current directory:

```bash
./json2xml < input.json
```

### Example

Input (`tests/valid/02_types.json`):

```json
{
  "age": 30,
  "height": 1.82,
  "employed": true,
  "retired": false,
  "nickname": null
}
```

Command:

```bash
./json2xml < ../tests/valid/02_types.json
```

Output (`output.xml`):

```xml
<root>
  <age>30</age>
  <height>1.82</height>
  <employed>true</employed>
  <retired>false</retired>
  <nickname>null</nickname>
</root>
```

### Error reporting

Invalid input is rejected with the position of the problem, and no output file is written:

```bash
$ ./json2xml < ../tests/invalid/13_trailing_comma.json
error at line 4, column 1: syntax error, unexpected }, expecting string
conversion failed, no output written
```

The exit code is `0` on success and `1` on error, so the tool can be used in scripts.

## Testing

Test inputs are grouped by the expected outcome:

- `tests/valid/`: well-formed JSON that must convert successfully
- `tests/invalid/`: malformed JSON that must be rejected

Run all tests from the repository root:

```bash
# every valid file must convert
for f in tests/valid/*.json; do
    ./src/json2xml < "$f" > /dev/null || echo "FAIL: $f"
done

# every invalid file must be rejected
for f in tests/invalid/*.json; do
    ./src/json2xml < "$f" 2> /dev/null && echo "UNEXPECTED PASS: $f"
done
```

No output from either loop means all tests passed.

## Project Structure

```
.
├── src/
│   ├── proiect.l           # Flex specification (lexer)
│   └── proiect.y           # Bison specification (parser + XML generation)
├── tests/
│   ├── valid/              # inputs that must convert successfully
│   └── invalid/            # inputs that must be rejected
├── Documentatie_LFT.pdf    # project report (Romanian)
├── .gitignore
├── LICENSE
└── README.md
```

Files generated during the build (`proiect.tab.c`, `proiect.tab.h`, `lex.yy.c`, the `json2xml` executable and `output.xml`) are excluded from version control.

## Limitations

The converter handles a practical subset of JSON. The following are **not** supported yet:

| Not supported | Example |
|---|---|
| Empty objects and arrays | `{}`, `[]` |
| Negative numbers and exponents | `-12.5`, `6.022e23` |
| Escape sequences in strings | `"say \"hi\""`, `"\u00e9"` |
| A value other than an object at the top level | `[1, 2, 3]` |
| Characters with special meaning in XML | `"Smith & Sons"`, `"a < b"` |
| Keys that are not valid XML names | `"first name"`, `"2fa"` |

Additionally:

- All values are written as text, so the XML does not record whether a value was a number, a string or a boolean.
- Nested elements are not indented according to their depth.

## Roadmap

- [ ] Support the full JSON specification (empty structures, all number formats, escape sequences)
- [ ] Escape XML special characters (`&`, `<`, `>`)
- [ ] Indent nested elements by depth
- [ ] Command-line options for the input and output files
- [ ] Reverse conversion: XML to JSON
- [ ] Automated tests with a `Makefile` and GitHub Actions


## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.
