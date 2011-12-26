*benchmark.txt*		Simple Benchmarking Tool for Vim script

Author  : h1mesuke <himesuke@gmail.com>
Updated : 2011-12-26
Version : 0.0.1
License : MIT license {{{

	Permission is hereby granted, free of charge, to any person obtaining
	a copy of this software and associated documentation files (the
	"Software"), to deal in the Software without restriction, including
	without limitation the rights to use, copy, modify, merge, publish,
	distribute, sublicense, and/or sell copies of the Software, and to
	permit persons to whom the Software is furnished to do so, subject to
	the following conditions:
	The above copyright notice and this permission notice shall be
	included in all copies or substantial portions of the Software.
	
	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
	EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
	MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
	IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
	CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
	TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
	SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
}}}

==============================================================================
CONTENTS					*benchmark-contents*

	Contents				|benchmark-contents|
	Introduction				|benchmark-introduction|
	How to Write a Benchmark		|benchmark-how-to-write|
	Interface				|benchmark-interface|
	  Functions				  |benchmark-fuctions|
	Issues					|benchmark-issues|
	Changelog				|benchmark-changelog|

==============================================================================
INTRODUCTION					*benchmark-introduction*

	*benchmark.vim* is a simple benchmarking tool for Vim script. It helps
	you to benchmark Vim scipt's code snippets and compare their
	performances.

	Requirements: ~
	* |+reltime| and |+float|

==============================================================================
HOW TO WRITE A BENCHMARK			*benchmark-how-to-write*

	1. Make a new benchmark script.
>
		$ vim bench_something.vim
<
	2. Create a new Benchmark object at your "bench_something.vim".
>
		let bm = benchmark#new("Something")
<
		* benchmark#new() returns a new Benchmark object.
		* benchmark#new()'s first argument will be used as a caption
		  of the benchmark in its report.
	
	3. Define some functions to be benchmarked.
>
		function! bm.bench_1()
		  " Do something...
		endfunction
	
		function! bm.bench_2()
		  " Do something...
		endfunction
<
		* Functions whose names start with "_" are ignored. You can
		  use "_" prefixed functions for private purpose.

	4. Call run().
>
		call bm.run()
<
		* You need to call Benchmark's run() method AFTER the
		  definitions of the functions to be benchmarked.

	5. Run the Benchmark.
>
		:source %
<
		or
>
		:QuickRun
<

		Results: >
		Benchmark: Something

		  bench_1 : 0.076685
		  bench_2 : 0.110060
<
==============================================================================
INTERFACE					*benchmark-interface*

------------------------------------------------------------------------------
FUNCTIONS					*benchmark-fuctions*

	benchmark#new( [caption])		*benchmark#new()*

	Creates a new Benchmark object.
	If [caption] is given, it will be used as a cation of the benchmark in
	its report.

	Example: >
	let bm = benchmark#new("Something")
<
BENCHMARK METHODS				*benchmark-methods*

	run( [n_try])				*benchmark-run()*

	Runs the benchmark and reports the results.
	If [n_try] is given, the benchmark is executed [n_try] times.

	Example: >
	call bm.run(3)
<
==============================================================================
ISSUES						*benchmark-issues*

	* Issues - h1mesuke/vim-benchmark - GitHub
	  https://github.com/h1mesuke/vim-benchmark/issues

==============================================================================
CHANGELOG					*benchmark-changelog*

0.0.1	2011-12-26

	* Initial version

vim:tw=78:ts=8:ft=help:norl:noet:ai
