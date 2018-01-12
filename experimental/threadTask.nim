import threadpool, os, times

template timeIt(name: static[string], it: untyped): untyped =
  var startTime = epochTime()
  it
  echo "Time taken for ", name, ": ", epochTime() - startTime

proc intensiveComputation[N: static[int]](x: ptr array[N, int]): int =
  var sum = 0
  for idx in 0 ..< N:
    sum += x[idx]
    # sleep(100)
  return sum

proc intensiveComputationOfFlowVar(fw: ptr seq[FlowVar[int]]; len: int): int =
  var sum = 0
  for idx in 0 ..< len:
    sum += ^fw[idx]
    # sleep(100)
  return sum

proc main =
  var data = [1, 2, 3, 4, 5, 6]
  timeIt "full await":
    timeIt "spawn":
      # in parallel:
      var
        results = newSeq[FlowVar[int]](5)
        postResults: FlowVar[int]
      for idx in 0 ..< 5:
        results[idx] = spawn intensiveComputation(data.addr)
      postResults = spawn intensiveComputationOfFlowVar(results.addr, 5)
    await postResults
  for result in results:
    echo ^result
  echo ^postResults

main()
