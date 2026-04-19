module main;

import std::io;
import std::time::clock;

import analyzer;

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

fn int main(String[] args) {

		io::printn("\n===PROGRAM START===\n");

  Clock clock_start = clock::now();
  String input_path = args.len > 1 ? args[1] : "";
  
  Analyzer? analyzer = analyzer::init(input_path);
  if(catch error = analyzer) {
    io::printfn(" Analyzer Initialization failed: %s", error);
    return 1;
  }
  defer {
    analyzer.deinit()!!;
    io::printn("Deinitialized correctly!");
  }


  if(catch error = analyzer.analyze()){
    io::printfn(" parse_text failed: %s", error);
    return 1;
  }

  if(catch error = analyzer.print()){
    io::printfn(" Trouble printing: %s", error);
    return 1;
  }

  NanoDuration end = clock::now() - clock_start;
  double secs = end.to_sec();
  io::printfn("%.15f seconds elapsed.", secs);

  io::printn("\n===PROGRAM END===\n");
	return 0;
}
