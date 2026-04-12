module main;

import std::io;
import std::time::clock;
import clean_room_temps;

fn int main(String[] args)
{
	String input_path = args.len > 1 ? args[1] : clean_room_temps::DEFAULT_INPUT_PATH;
	Clock start = clock::now();

	if (catch err = clean_room_temps::run(input_path))
	{
		io::eprintfn("clean_room_temps failed: %s", err);
		return 1;
	}

	NanoDuration elapsed = clock::now() - start;
	io::printfn("Elapsed: %.6f seconds", elapsed.to_sec());
	return 0;
}
