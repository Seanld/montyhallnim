import std/cmdline
import std/strutils
import std/parseopt
import std/random

when compileOption("profiler"):
  import std/nimprof

# Initialize RNG.
randomize()

# Get and parse command line arugments.
let argStr = commandLineParams().join(" ")
var parsed = initOptParser(argStr)

type DoorOption = enum
  Goat
  Car

type Door = ref object
  content: DoorOption

var
  doorCount: int = 3
  samples: int = 10
  threads: int = 1

# Iterate through arguments/options.
while true:
  parsed.next()
  case parsed.kind
  of cmdEnd: break
  of cmdShortOption, cmdLongOption:
    case parsed.key
    of "d", "doors":
      doorCount = parseInt(parsed.val)
    of "s", "samples":
      samples = parseInt(parsed.val)
    of "t", "threads":
      threads = parseInt(parsed.val)
  of cmdArgument:
    # echo "Argument: ", parsed.key
    discard

when compileOption("profiler"):
  enableProfiling()

# Define utility functions to simplify main loop.

proc generateDoors(doors: seq[Door]) =
  # Reset `doors`. Re-allocating on every call is slow.
  for i in 0 ..< doorCount:
    doors[i].content = Goat
  doors[rand(0 .. doorCount-1)].content = Car

var resultsChan: Channel[float]
resultsChan.open()

# Run `args.n` simulations of the Monty Hall problem, using
# unique `Rand` instance `args.r`.
proc simulateN(r: var Rand, n: int) {.thread.} =
  var
    wins: int
    losses: int
    unopened = newSeq[int]()
    doors = newSeq[Door]()

  for _ in 0 ..< doorCount:
    doors.add(Door(
      content: Goat
    ))

  for x in 0 ..< n:
    # Reset existing `unopened` seq. Faster than allocating a
    # new seq on every iteration.
    for j in 0 ..< unopened.len:
      unopened.del(0)

    generateDoors(doors)

    for j in 0 ..< doorCount:
      unopened.add(j)

    let firstDoorIndex = sample(r, unopened)
    if doors[firstDoorIndex].content == Car:
      wins += 1
      continue
    unopened.delete(firstDoorIndex)

    let secondDoorIndex = sample(r, unopened)
    if doors[secondDoorIndex].content == Car:
      wins += 1
      continue

    losses += 1

  resultsChan.send(wins / (wins + losses))

proc simulate(n: int) {.thread.} =
  var uniqueRand = initRand()
  simulateN(uniqueRand, n)

var
  rateSum: float
  tasks = newSeq[Thread[int]](threads)

for t in 0 ..< threads:
  createThread[int](
    tasks[t],
    simulate,
    int(samples / threads),
  )

for t in 0 ..< threads:
  rateSum += resultsChan.recv()

echo "Win rate: ", (rateSum / float(threads)) * 100, "%"
