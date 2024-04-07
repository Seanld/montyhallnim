import std/cmdline
import std/strutils
import std/parseopt
import std/random

# Initialize RNG.
randomize()

# Get and parse command line arugments.
let argStr = commandLineParams().join(" ")
var parsed = initOptParser(argStr)

type DoorOption = enum
  Goat
  Car

type Door = object
  known: bool
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

# Define utility functions to simplify main loop.

proc generateDoors(n: int = doorCount): seq[Door] =
  result = newSeq[Door](n)
  result[rand(0 .. n-1)].content = Car

proc chooseRandomDoor(rand: var Rand, doors: seq[Door]): int =
  var availableDoors = newSeq[int](0)
  for i, door in doors:
    if not door.known:
      availableDoors.add(i)
  sample(rand, availableDoors)

var resultsChan: Channel[float]
resultsChan.open()

# Run `args.n` simulations of the Monty Hall problem, using
# unique `Rand` instance `args.r`.
proc simulateN(r: var Rand, n: int) {.thread.} =
  var
    wins: int
    losses: int

  for x in 0 ..< n:
    var currentDoors = generateDoors()

    let firstDoorIndex = chooseRandomDoor(r, currentDoors)
    if currentDoors[firstDoorIndex].content == Car:
      wins += 1
      continue
    currentDoors[firstDoorIndex].known = true

    let secondDoorIndex = chooseRandomDoor(r, currentDoors)
    if currentDoors[secondDoorIndex].content == Car:
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
