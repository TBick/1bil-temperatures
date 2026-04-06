# testc3

Small C3 project for generating and analyzing synthetic temperature data.

## Targets

- `generate_temps` writes records in `STATION;TEMP` format.
- `analyze_temps` reads a temperature file and prints min, max, average, and total rows processed.

Example record:

```text
NYC;26.4
```

## Build

```sh
c3c build generate_temps
c3c build analyze_temps
```

## Run

Generate a small file:

```sh
./build/generate_temps resources/generated_temperatures.txt 1000 250
```

Analyze a file:

```sh
./build/analyze_temps resources/generated_temperatures.txt
```

## Notes
- Both binaries reference ./resources, which does not exist in this repo. Create resource folder before running any binaries. `mkdir -p resources/` 
