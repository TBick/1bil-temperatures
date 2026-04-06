module main;

import std::io;
import generate_temps;

fn int main(String[] args)
{
	String output_path = args.len > 1 ? args[1] : generate_temps::DEFAULT_OUTPUT_PATH;

	ulong? line_count_opt = parse_ulong_arg(args, 2, generate_temps::DEFAULT_LINE_COUNT);
	if (catch err = line_count_opt)
	{
		io::eprintfn("Invalid line count '%s': %s", args[2], err);
		return 1;
	}
	ulong line_count = line_count_opt;

	ulong? progress_interval_opt = parse_ulong_arg(args, 3, generate_temps::DEFAULT_PROGRESS_INTERVAL);
	if (catch err = progress_interval_opt)
	{
		io::eprintfn("Invalid progress interval '%s': %s", args[3], err);
		return 1;
	}
	ulong progress_interval = progress_interval_opt;

	if (progress_interval == 0)
	{
		io::eprintn("Progress interval must be greater than 0.");
		return 1;
	}

	if (catch err = generate_temps::generate_temperature_file(output_path, line_count, progress_interval))
	{
		io::eprintfn("Generation failed: %s", err);
		return 1;
	}

	io::printfn("Finished writing %d rows to %s", line_count, output_path);
	return 0;
}

fn ulong? parse_ulong_arg(String[] args, usz index, ulong fallback)
{
	if (index >= args.len)
	{
		return fallback;
	}
	return args[index].to_ulong();
}
