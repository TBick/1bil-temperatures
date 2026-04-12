# testc3

Small C3 project for generating and analyzing synthetic temperature data.

## Targets

- `generate_temps-release` writes records in `STATION;TEMP` format.
- `analyze_temps-debug` and `analyze_temps-release` are the existing analyzer builds.
- `clean_room_temps` is a separate reference implementation focused on clear, idiomatic C3 structure. (THIS IS CODEX'S INTERPRETATION)

Example record:

```text
NYC;26.4
```

## Build

```sh
c3c build generate_temps-release
c3c build analyze_temps-debug
c3c build analyze_temps-release
c3c build clean_room_temps
```

## Run

Generate a small file:

```sh
./build/generate_temps-release resources/generated_temperatures.txt 1000 250
```

Analyze a file with the original analyzer:

```sh
./build/analyze_temps-debug resources/generated_temperatures.txt
```

Analyze a file with the clean-room reference target:

```sh
./build/clean_room_temps resources/generated_temperatures.txt
```

## Resources

- `resources/` already exists in this repo.
- `resources/generated_temperatures.txt` is the default input file used by the generator and the new clean-room analyzer.

## clean_room_temps

`clean_room_temps` exists as a deliberate contrast to the exploratory `analyze_temps` implementation.
Its purpose is to show one way to structure the same problem with a more conventional C3 style:

- small functions with single responsibilities
- buffered IO instead of manual byte-walking in the application code
- explicit validation for malformed records
- clear ownership of temporary vs. heap-backed data
- source-level documentation that explains why the code is shaped the way it is

Use it as a learning target when you want to study organization, parsing boundaries, and error handling without mixing that discussion with the experiments in `analyze_temps`.

## Benchmark Notes

The two analyzers are not trying to optimize for the same thing.

Using the existing `resources/generated_temperatures.txt` file with 1,000,000,000 rows from the repository root:

- `./build/analyze_temps-release` completed in `16.555553418999999` seconds
- `./build/clean_room_temps` completed in `144.177572` seconds

That makes `clean_room_temps` about `8.7x` slower on this workload.

Implications:

- `analyze_temps-release` is currently the throughput-oriented parser and is the better target for raw parsing-speed experiments.
- `clean_room_temps` is a readability and structure reference, not a performance reference.
- The main reason for the gap is design tradeoff: `clean_room_temps` uses higher-level line reading, stricter validation, and more general parsing helpers, while `analyze_temps-release` parses directly from a large byte buffer with fewer abstractions in the hot path.
- The average output differs slightly (`23.5` vs `23.6`) because `clean_room_temps` computes the average with floating-point division, while `analyze_temps-release` currently truncates during integer division before printing.
