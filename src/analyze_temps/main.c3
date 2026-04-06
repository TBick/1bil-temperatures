module main;

import std::io;
import std::io::file;
import std::time::clock;
import std::core::ascii;


//  TODO
//    We are going to test reading and parsing lines in a single Thread
//    Need to establish performance metrics
//    Read lines and parse
//    Perform analysis on data as we parse
//    Output analysis
//    Output performance metrics

//    Things I need to read the standard library
//      Timing mechanisms (std::time?)
//      Buffers, Readers, Streams
//      std.math -> analysis
//      Considerations for 1Billion lines of text
//        Cant hold the whole file in RAM (assumption) DO NOT TRY TO
//      Error Handling in the case of failure 
//        THERE WILL BE MANY FAILURES

//    Future considerations when exploring multithreading:
//      Concurrency VS Parallelism
//      Abstracting things into separate module or file before multi-threading
//      Argument Parsing and Handling (minimal at first)
//      Collaborate into Git/Github if necessary

const int READ_BUF_SIZE = 128 * 128;
const String DEFAULT_PROJECT_ROOT_INPUT = "resources/generated_temperatures.txt";
const String DEFAULT_BUILD_DIR_INPUT = "../resources/generated_temperatures.txt";




struct Analysis {
  char[4] min_station_buffer;
  int min_station_buffer_index;
  float min;

  char[4] max_station_buffer;
  int max_station_buffer_index;
  float max;

  double avg;

  double total;
  long lines_read;
}

struct Parser {
  ulong index;
 
  char[4] station;
  int station_i;

  char[5] temp;
  int temp_i;
  
}





fn int main(String[] args) {

		io::printn("\n===PROGRAM START===\n");

  Clock clock_start = clock::now();
  String input_path = args.len > 1 ? args[1] : "";
  
  Analysis analysis = {};
  analysis.min_station_buffer_index = 0;
  analysis.max_station_buffer_index = 0;
  analysis.total = 0;
  analysis.lines_read = 0;

  io::printn("  Parsing Text");
  if(catch error = parse_text(&analysis, input_path)) {
    io::printfn(" parse_text failed: %s", error);
    return 1;
  }

  NanoDuration end = clock::now() - clock_start;
  double secs = end.to_sec();
  io::printfn("%.15f seconds elapsed.", secs);

  io::printn("\n===PROGRAM END===\n");
	return 0;
}






fn void? parse_text(Analysis *analysis, String input_path) {

  //  Open File
  File text = open_input_file(input_path)!;
  defer (void)text.close();

  char[READ_BUF_SIZE] read_buffer;

  //  Initialize Parser
  Parser parser;
  parser.temp_i = 0;
  parser.station_i = 0;




  // Continuous loop
  while(true) {
    //  Throw text into buffer -> n is the byte size
    usz n = text.read(&read_buffer)!;
    if (!n) break; // Exit loop if no bytes are read

    //  Handle each character in the read_buffer
    foreach (c : read_buffer[:n]) {
    
    

      //  Match statements
      switch {
        case c.is_alpha():
          parser.station[parser.station_i] = c;
          parser.station_i++;
          continue;

        case (c.is_digit() || c == '.' || c == '-'):
          parser.temp[parser.temp_i] = c;
          parser.temp_i++;
          continue;

        case c == ';':
          continue;

        case c == '\n':
          break;
          
      }

      // If reached here, NewLine has been found
      //  Need to crunch the data for that line and
      //  reset for next line

      //  (String)station[..station_i] -> converts station to String
      //  ((String)temp[..(temp_i-1)]).to_float()! -> temp to float

      // NOTE: temp[..temp_i] is INCLUSIVE.
      //  This means temp[temp_i] is INCLUDED within the slice itself.
      


      //String station = (String)parser.station[..parser.station_i];
      String temp_str = ((String)parser.temp[..(parser.temp_i-1)]);
      float temp = temp_str.to_float()!;

      //  Get min/max statistics
      switch {

        //  If lower than current min
        case temp < analysis.min:
          analysis.min_station_buffer[:parser.station_i] = 
            parser.station[:parser.station_i];
          analysis.min_station_buffer_index = parser.station_i;
          analysis.min = temp;

        //  If higher than current max
        case temp > analysis.max:
          analysis.max_station_buffer[:parser.station_i] =
            parser.station[:parser.station_i];
          analysis.max_station_buffer_index = parser.station_i;
          analysis.max = temp;

      }
      
      analysis.total += (double)temp;

      parser.station_i = 0;
      parser.temp_i = 0;
      
      analysis.lines_read++;
    }
  }

  // Calculate average after totals
  analysis.avg = analysis.total / analysis.lines_read;


  io::printn("Finished Parsing");
  io::printfn(" Parsed %d lines", analysis.lines_read);
  print_analysis(analysis)!;
  
}






fn File? open_input_file(String input_path) {
  if (input_path.len > 0) {
    return file::open(input_path, "rb");
  }
  
  // Succeeds if ran from root
  if (file::exists(DEFAULT_PROJECT_ROOT_INPUT)) {
    return file::open(DEFAULT_PROJECT_ROOT_INPUT, "rb");
  }
  
  //  Succeeds if ran from build directory
  if (file::exists(DEFAULT_BUILD_DIR_INPUT)) {
    return file::open(DEFAULT_BUILD_DIR_INPUT, "rb");
  }

  return io::FILE_NOT_FOUND~;
}

fn void? print_analysis(Analysis *analysis) {
  io::printn("--Printing Analysis--");
  io::printfn("    Minimum Station Temp: %f, %s",
    analysis.min,
    (String)analysis.min_station_buffer[
      :analysis.min_station_buffer_index
    ]);
  io::printfn("   Maximum Station Temp: %f, %s",
    analysis.max,
    (String)analysis.max_station_buffer[
      :analysis.max_station_buffer_index
    ]);
  io::printfn("   Average Temp: %.1f", analysis.avg);
  io::printfn("   Total Reads: %d", analysis.lines_read);
  io::printfn("");
  
}
