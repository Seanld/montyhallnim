# Explanation

This is the Nim equivalent of my Go implementation simulating the "choose another door every
time" strategy in the Monty Hall problem. I wrote the Go one when I heard about the problem,
because it piqued my interest, and I wanted to very it with a large sample size. The Nim version
came about both to learn Nim, and to compare its performance to Go.

I was curious how much I could optimize it, and much further I could push it than I could in Go.
The answer to that question appears to be that Go's goroutines are really good. In a single-core
setting, Nim blows the Go version out of the water. When more cores are taken advantage of, the
Nim version lags behind, and Go starts to pull ahead as more goroutines/threads are added. I could
be missing something obvious in the Nim version with threads that would greatly speed it up, but
as of writing this, I believe I've optimized it to a great degree.

# Running

Clone this repository, and build with Nimble:

```
$ nimble build -d:release --opt:speed
```

The binary will be placed in the root directory of the project.

## Options

You can configure the sim with a few arguments:

- `-d:{int}` or `--doors:{int}`: How many doors there are, where `{int}` is an integer.
- `-s:{int}` or `--samples:{int}`: How many samples (sim iterations) to run, where `{int}` is an integer.
- `-t:{int}` or `--threads:{int}`: How many threads to use, equally splitting the samples to each, where `{int}` is an integer.

As an example, let's run it with 5 doors, 1,000,000 samples/iterations, and 2 threads:

```
$ ./montyhall -d:5 -s:1000000 -t:2
```
