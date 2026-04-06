module generate_temps;

import std::io;
import std::io::file;
import std::math;
import std::math::distributions;
import std::math::random;

const String DEFAULT_OUTPUT_PATH = "resources/generated_temperatures.txt";
const ulong DEFAULT_LINE_COUNT = 1000000000UL;
const ulong DEFAULT_PROGRESS_INTERVAL = 2500UL;
const usz WRITE_BUFFER_BYTES = 32 * 1024;
const usz STATION_COUNT = 12;

struct StationTemplate
{
	String name;
	double baseline_mean;
	double baseline_sigma;
}

struct StationProfile
{
	String name;
	double mean;
	double sigma;
}

const StationTemplate[] STATION_TEMPLATES = {
	{ "CHI", 11.0, 7.0 },
	{ "LA", 21.0, 5.0 },
	{ "NYC", 13.0, 7.0 },
	{ "DAL", 20.0, 6.5 },
	{ "MIA", 27.0, 4.5 },
	{ "SEA", 15.0, 5.5 },
	{ "PHX", 29.0, 6.0 },
	{ "BOS", 10.0, 7.0 },
	{ "SFO", 17.0, 4.0 },
	{ "DEN", 9.0, 8.0 },
	{ "ATL", 19.0, 6.0 },
	{ "HOU", 24.0, 6.0 },
};

fn void? generate_temperature_file(
	String output_path,
	ulong line_count = DEFAULT_LINE_COUNT,
	ulong progress_interval = DEFAULT_PROGRESS_INTERVAL)
{
	io::File output = file::open(output_path, "wb")!;
	defer (void)output.close();

	char[WRITE_BUFFER_BYTES] write_storage;
	io::WriteBuffer writer;
	writer.init(&output, write_storage[..]);
	random::DefaultRandom rng;
	random::seed_entropy(&rng);
	StationProfile[STATION_COUNT] stations;
	build_station_profiles(&rng, stations[..]);

	io::printfn("Writing %d rows to %s", line_count, output_path)!;

	for (ulong generated = 0; generated < line_count; generated++)
	{
		usz station_index = (usz)random::next(&rng, (uint)STATION_COUNT);
		int temp_tenths = sample_temperature_tenths(&rng, stations[station_index]);
		ulong completed = generated + 1;

		write_record(&writer, stations[station_index].name, temp_tenths)!;

		if (completed % progress_interval == 0)
		{
			report_progress(completed, line_count)!;
		}
	}

	if (line_count == 0 || line_count % progress_interval != 0)
	{
		report_progress(line_count, line_count)!;
	}

	writer.flush()!;
	io::printn();
}

fn void build_station_profiles(random::DefaultRandom* rng, StationProfile[] profiles)
{
	double seasonal_shift = random_double_in_range(rng, -6.0, 6.0);
	double volatility_scale = random_double_in_range(rng, 0.85, 1.15);
	foreach (i, template : STATION_TEMPLATES)
	{
		double local_shift = random_double_in_range(rng, -3.0, 3.0);
		double local_sigma_scale = random_double_in_range(rng, 0.85, 1.20);
		double mean = template.baseline_mean + seasonal_shift + local_shift;
		double sigma = math::max(2.5, template.baseline_sigma * volatility_scale * local_sigma_scale);
		profiles[i] = { template.name, mean, sigma };
	}
}

fn double random_double_in_range(random::DefaultRandom* rng, double min, double max)
{
	return min + random::next_double(rng) * (max - min);
}

fn int sample_temperature_tenths(random::DefaultRandom* rng, StationProfile station)
{
	distributions::NormalDist distribution = distributions::normal(station.mean, station.sigma);
	double sample = distribution.random(rng);
	return (int)math::round(sample * 10.0);
}

fn void? report_progress(ulong generated, ulong total)
{
	io::printf("\rGenerated %d / %d lines", generated, total)!;
	io::stdout().flush()!!;
}

fn void? write_record(io::WriteBuffer* writer, String station, int temp_tenths)
{
	int absolute_tenths = math::abs(temp_tenths);
	int whole = absolute_tenths / 10;
	int fractional = absolute_tenths % 10;

	writer.write(station)!;
	writer.write_byte(';')!;

	if (temp_tenths < 0)
	{
		writer.write_byte('-')!;
	}

	io::fprintf(writer, "%d.%d\n", whole, fractional)!;
}
