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
  firstTry: int
  secondTry: int
  fail: int

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

func openedDoors(doors: seq[Door]): seq[int] =
  for i, door in doors:
    if door.known:
      result.add(i)

proc chooseRandomDoor(rand: var Rand, doors: seq[Door]): int =
  var availableDoors = newSeq[int](0)
  for i, door in doors:
    if not door.known:
      availableDoors.add(i)
  sample(rand, availableDoors)

# Run `n` simulations of the Monty Hall problem.
proc simulate(chan: var Channel[float], n: int) {.thread.} =
  var
    uniqueRand = initRand()
    wins: int
    losses: int

  for x in 0 .. n-1:
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

  chan.send(wins / losses)

var resultChannels: seq[Channel[float]]
var allThreads: seq[Thread[void]]
var sumWinRate: float

for t in 0 .. threads-1:
  var chunkSize = int(samples / t)
  var newChannel: Channel[float]
  newChannel.open()
  resultChannels.add(newChannel)

  simulate(newChannel, chunkSize)
  for chan in resultChannels:
    sumWinRate += chan.recv()
