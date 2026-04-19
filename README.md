# 1bil-temps

Small C3 project for generating and analyzing synthetic temperature data.

## Prerequisites

- Install `c3c` and make sure it is available on `PATH`.
- Run commands from the repository root.

This repository's `.gitignore` excludes `build/` and the entire `resources/` tree. That means a fresh clone will not include compiled binaries, generated datasets, or any local reference files you may have kept under `resources/`.

## Targets

- `generate_temps-release`: writes synthetic records in `STATION;TEMP` format.
- `analyze_temps-debug`: debug analyzer build from `src/analyze_temps`.
- `analyze_temps-release`: optimized analyzer build from `src/analyze_temps`.
- `clean_room_temps`: reference analyzer focused on structure and validation over raw throughput.

## Data Format

Records are newline-delimited text:

```text
NYC;26.4
```

The bundled generator currently emits short station codes and temperatures with one decimal place.

## Source Layout

- `src/analyze_temps/main.c3`: entry point, timing, argument handling, and analyzer lifecycle.
- `src/analyze_temps/analyzer.c3`: file opening, chunked parsing, aggregation, and result printing.
- `src/generate_temps/`: synthetic data generator.
- `src/clean_room_temps/`: clearer reference implementation of the same problem.

## Build

```sh
c3c build generate_temps-release
c3c build analyze_temps-debug
c3c build analyze_temps-release
c3c build clean_room_temps
```

Build outputs are written to `build/`.

## Run

For a clean clone, create a local `resources/` directory first if you want to use the default paths shown below:

```sh
mkdir -p resources
```

Generate a small file:

```sh
./build/generate_temps-release resources/generated_temperatures.txt 1000 250
```

Generator arguments are:

- output path
- line count
- progress interval

If omitted, the generator defaults to `resources/generated_temperatures.txt`, `1000000000` rows, and a progress update every `2500` rows.

Because `resources/` is ignored by git, that default output path only works after you create the directory locally.

Analyze a file:

```sh
./build/analyze_temps-debug resources/generated_temperatures.txt
./build/analyze_temps-release resources/generated_temperatures.txt
```

Run the reference analyzer:

```sh
./build/clean_room_temps resources/generated_temperatures.txt
```

If you do not want to use `resources/`, pass explicit file paths to both the generator and analyzers:

```sh
./build/generate_temps-release /tmp/generated_temperatures.txt 1000 250
./build/analyze_temps-debug /tmp/generated_temperatures.txt
./build/analyze_temps-release /tmp/generated_temperatures.txt
./build/clean_room_temps /tmp/generated_temperatures.txt
```

## Input Resolution

If no path is provided, `analyze_temps` tries:

1. `resources/generated_temperatures.txt`
2. `../resources/generated_temperatures.txt`

Those fallback paths are local filesystem conventions, not tracked repository assets.

## Notes

- `analyze_temps` reads the file in `1 MiB` chunks and carries partial lines across buffer boundaries.
- `analyze_temps` stores totals in tenths and currently computes the displayed average with integer division.
- `clean_room_temps` is intended as a readability and organization reference, not the main performance target.
- A local `resources/std` copy is optional reference material only; builds use the installed C3 toolchain's standard library.

## Current Limitations

- `analyze_temps` currently assumes the short station identifiers used by the bundled generator. Longer station names are not handled yet.
- Empty input files are not currently handled by `analyze_temps`.
