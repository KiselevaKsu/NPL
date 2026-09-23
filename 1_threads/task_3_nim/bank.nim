import std/[typedthreads, locks, os, strformat, random]

# общий счёт и синхронизация
var
  balance: int
  balanceLock: Lock
  canWithdraw: Cond

const
  NUM_READERS = 3
  NUM_WRITERS = 3
  NUM_OPS     = 5
  INITIAL     = 1000

# читатель: читает баланс и печатает
proc reader(id: int) {.thread.} =
  for i in 1 .. NUM_OPS:
    acquire(balanceLock)
    let b = balance
    release(balanceLock)
    echo &"reader {id}: balance = {b}"
    sleep(10)

# писатель: пополняет или снимает
proc writer(args: tuple[id: int, deposit: bool]) {.thread.} =
  let id = args.id
  let deposit = args.deposit
  for i in 1 .. NUM_OPS:
    let amount = rand(50 .. 200)
    acquire(balanceLock)
    if deposit:
      balance += amount
      echo &"writer {id} (deposit): +{amount}, balance = {balance}"
      signal(canWithdraw)
    else:
      while balance < amount:
        wait(canWithdraw, balanceLock)
      balance -= amount
      echo &"writer {id} (withdraw): -{amount}, balance = {balance}"
    release(balanceLock)
    sleep(20)

when isMainModule:
  initLock(balanceLock)
  initCond(canWithdraw)
  balance = INITIAL

  echo &"initial balance: {balance}"
  echo &"readers: {NUM_READERS}, writers: {NUM_WRITERS}, ops each: {NUM_OPS}"

  var
    readers: array[NUM_READERS, Thread[int]]
    writers: array[NUM_WRITERS, Thread[tuple[id: int, deposit: bool]]]
    writersArgs: array[NUM_WRITERS, tuple[id: int, deposit: bool]]

  for i in 0 ..< NUM_READERS:
    createThread(readers[i], reader, i)

  for i in 0 ..< NUM_WRITERS:
    writersArgs[i] = (id: i, deposit: (i mod 2 == 0))
    createThread(writers[i], writer, writersArgs[i])

  joinThreads(readers)
  joinThreads(writers)

  echo &"final balance: {balance}"
  deinitCond(canWithdraw)
  deinitLock(balanceLock)