module clean_room_temps;

import std::core::mem::allocators;
import std::io;
import std::io::file;

const String DEFAULT_INPUT_PATH = "resources/generated_temperatures.txt";
const usz READ_BUFFER_BYTES = 64 * 1024;

faultdef INVALID_RECORD, INVALID_TEMPERATURE, NO_ROWS;

<*
 A parsed input row.

 The analyzer keeps the record format simple on purpose:
 each line should be `STATION;TEMP`, where `TEMP` has a single decimal place.
*>
struct TemperatureRecord
{
	String station;
	int temperature_tenths;
}

<*
 Tracks either the minimum or maximum observed record.

 The station name is copied onto the heap so it remains valid after the
 line buffer is reused for the next read.
*>
struct Extremum
{
	bool initialized;
	String station;
	int temperature_tenths;
}

<*
 Aggregated statistics for the full file.

 The summary stores total temperature in tenths to avoid losing precision
 while the file is streamed line by line.
*>
struct Summary
{
	ulong row_count;
	long total_tenths;
	Extremum min;
	Extremum max;
}

<*
 Run the clean-room analyzer and print a short report.

 This target is meant to be a reference-style implementation that favors:
 - small functions
 - explicit validation
 - buffered IO
 - clear ownership of temporary and heap data
*>
fn void? run(String input_path)
{
	Summary summary = {};
	defer summary.free();

	analyze_file(input_path, &summary)!;
	print_summary(input_path, &summary)!;
}

<*
 Release heap-owned station names captured for the minimum and maximum rows.
*>
fn void Summary.free(&self)
{
	self.min.station.free(&allocators::LIBC_ALLOCATOR);
	self.max.station.free(&allocators::LIBC_ALLOCATOR);
}

<*
 Stream the input file one line at a time and update the summary as records
 are parsed.
*>
fn void? analyze_file(String input_path, Summary* summary)
{
	io::File input = file::open(input_path, "rb")!;
	defer (void)input.close();

	char[READ_BUFFER_BYTES] read_storage;
	io::ReadBuffer reader;
	reader.init(&input, read_storage[..]);

	ulong line_number = 0;
	while (true)
	{
		String? line_result = io::readline(&allocators::LIBC_ALLOCATOR, &reader);
		if (catch err = line_result)
		{
			if (err == io::EOF) break;
			return err~;
		}

		line_number++;
		String line = line_result;
		defer line.free(&allocators::LIBC_ALLOCATOR);

		if (!line.len)
		{
			report_input_error(line_number, "empty lines are not valid records");
			return INVALID_RECORD~;
		}

		TemperatureRecord record = parse_record(line, line_number)!;
		update_summary(summary, record);
	}

	if (summary.row_count == 0)
	{
		io::eprintfn("No temperature rows were found in %s.", input_path);
		return NO_ROWS~;
	}
}

<*
 Parse a single input line into a station name and a temperature in tenths.
*>
fn TemperatureRecord? parse_record(String line, ulong line_number)
{
	usz? separator_result = line.index_of_char(';');
	if (catch err = separator_result)
	{
		report_input_error(line_number, "missing ';' separator");
		return INVALID_RECORD~;
	}

	usz separator = separator_result;
	if (separator == 0 || separator == line.len - 1)
	{
		report_input_error(line_number, "records must look like STATION;TEMP");
		return INVALID_RECORD~;
	}

	String station = line[:separator];
	String temperature_text = line[separator + 1..];
	if (@ok(temperature_text.index_of_char(';')))
	{
		report_input_error(line_number, "records may only contain one ';' separator");
		return INVALID_RECORD~;
	}

	return {
		.station = station,
		.temperature_tenths = parse_temperature_tenths(temperature_text, line_number)!,
	};
}

<*
 Parse temperatures like `21.4` or `-7.2` into integer tenths.

 The function is strict on purpose so malformed input fails early and clearly.
*>
fn int? parse_temperature_tenths(String text, ulong line_number)
{
	bool negative = text.starts_with("-");
	if (negative)
	{
		text = text[1..];
	}

	if (!text.len)
	{
		report_input_error(line_number, "temperature is missing after the sign");
		return INVALID_TEMPERATURE~;
	}

	usz? decimal_result = text.index_of_char('.');
	if (catch err = decimal_result)
	{
		report_input_error(line_number, "temperature must include exactly one decimal place");
		return INVALID_TEMPERATURE~;
	}

	usz decimal = decimal_result;
	if (decimal == 0 || decimal + 2 != text.len)
	{
		report_input_error(line_number, "temperature must use one digit after the decimal point");
		return INVALID_TEMPERATURE~;
	}

	String whole_text = text[:decimal];
	String tenths_text = text[decimal + 1..];

	int? whole_result = whole_text.to_int();
	if (catch err = whole_result)
	{
		report_input_error(line_number, "temperature whole-number portion is invalid");
		return INVALID_TEMPERATURE~;
	}

	int? tenths_result = tenths_text.to_int();
	if (catch err = tenths_result)
	{
		report_input_error(line_number, "temperature fractional portion is invalid");
		return INVALID_TEMPERATURE~;
	}

	int whole = whole_result;
	int tenths = tenths_result;
	if (tenths < 0 || tenths > 9)
	{
		report_input_error(line_number, "temperature fractional portion must be a single digit");
		return INVALID_TEMPERATURE~;
	}

	int value = whole * 10 + tenths;
	return negative ? -value : value;
}

<*
 Fold one parsed record into the running summary.
*>
fn void update_summary(Summary* summary, TemperatureRecord record)
{
	summary.row_count++;
	summary.total_tenths += record.temperature_tenths;

	if (!summary.min.initialized || record.temperature_tenths < summary.min.temperature_tenths)
	{
		assign_extremum(&summary.min, record);
	}

	if (!summary.max.initialized || record.temperature_tenths > summary.max.temperature_tenths)
	{
		assign_extremum(&summary.max, record);
	}
}

<*
 Replace the current extremum with the latest record.
*>
fn void assign_extremum(Extremum* extremum, TemperatureRecord record)
{
	extremum.station.free(&allocators::LIBC_ALLOCATOR);
	extremum.station = record.station.copy(&allocators::LIBC_ALLOCATOR);
	extremum.temperature_tenths = record.temperature_tenths;
	extremum.initialized = true;
}

<*
 Print the final report once the file has been fully processed.
*>
fn void? print_summary(String input_path, Summary* summary)
{
	io::printfn("== clean_room_temps ==")!;
	io::printfn("Input: %s", input_path)!;
	io::printfn("Rows processed: %d", summary.row_count)!;
	print_extremum("Minimum", &summary.min)!;
	print_extremum("Maximum", &summary.max)!;
	io::printfn("Average: %.1f", average_celsius(summary))!;
}

<*
 Convert the accumulated temperature sum to Celsius for display.
*>
fn double average_celsius(Summary* summary)
{
	return ((double)summary.total_tenths / (double)summary.row_count) / 10.0;
}

<*
 Print either the minimum or maximum record in `12.3 at STATION` form.
*>
fn void? print_extremum(String label, Extremum* extremum)
{
	int magnitude = extremum.temperature_tenths < 0 ? -extremum.temperature_tenths : extremum.temperature_tenths;
	int whole = magnitude / 10;
	int tenths = magnitude % 10;

	io::printfn("%s: %s%d.%d at %s",
		label,
		extremum.temperature_tenths < 0 ? "-" : "",
		whole,
		tenths,
		extremum.station)!;
}

fn void report_input_error(ulong line_number, String message)
{
	(void)io::eprintfn("Input error on line %d: %s", line_number, message);
}
