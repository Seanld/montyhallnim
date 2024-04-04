import std/cmdline
import std/strutils
import std/parseopt
import std/random
import std/locks

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

# # This needs to be global so it can be accessed by the utility functions too.
# var resultChannels: seq[Channel[float]]

var
  sumLock: Lock
  sumWinRate {.guard: sumLock.}: float = 0

# Run `n` simulations of the Monty Hall problem.
proc simulate(n: int) {.nimcall.} =
  echo n
  var
    uniqueRand = initRand()
    wins: int
    losses: int

  for x in 0 ..< n:
    var currentDoors = generateDoors()

    let firstDoorIndex = chooseRandomDoor(uniqueRand, currentDoors)
    if currentDoors[firstDoorIndex].content == Car:
      wins += 1
      continue
    currentDoors[firstDoorIndex].known = true

    let secondDoorIndex = chooseRandomDoor(uniqueRand, currentDoors)
    if currentDoors[secondDoorIndex].content == Car:
      wins += 1
      continue

    losses += 1

  withLock sumLock:
    var sumWinRateCopy = sumWinRate
    sumWinRateCopy += wins / losses
    sumWinRate = sumWinRateCopy

var workers: array[4, Thread[int]]

for t in 0 .. 3:
  var
    chunkSize = int(samples / t)
    newThread: Thread[int]

  createThread(newThread, simulate, chunkSize)
  workers[t] = newThread

joinThreads(workers)

echo sumWinRate
