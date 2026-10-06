----------------------------- MODULE LiveUpdate -----------------------------
EXTENDS Naturals, Sequences, FiniteSets
VARIABLES version, phase, queue, flight, flight_version, accepted, completed,
          completed_values, candidate, corrupt, remaining, attempted, outcome
vars == <<version, phase, queue, flight, flight_version, accepted, completed,
          completed_values, candidate, corrupt, remaining, attempted, outcome>>
Ids == {1, 2, 3}
Elements(s) == {s[i] : i \in 1..Len(s)}
Outstanding == Len(queue) + IF flight = 0 THEN 0 ELSE 1
Init == /\ version = 1 /\ phase = "running" /\ queue = <<>>
        /\ flight = 0 /\ flight_version = 0 /\ accepted = {}
        /\ completed = <<>> /\ completed_values = <<>> /\ candidate = <<>>
        /\ corrupt = FALSE /\ remaining = 0 /\ attempted = FALSE
        /\ outcome = "none"
Enqueue1 ==
    /\ 1 \notin accepted
    /\ phase \notin {"copying", "ready"}
    /\ Outstanding < 2
    /\ queue' = Append(queue, 1) /\ accepted' = accepted \cup {1}
    /\ UNCHANGED <<version, phase, flight, flight_version, completed,
                    completed_values, candidate, corrupt, remaining, attempted, outcome>>
Enqueue2 ==
    /\ 2 \notin accepted
    /\ phase \notin {"copying", "ready"}
    /\ Outstanding < 2
    /\ queue' = Append(queue, 2) /\ accepted' = accepted \cup {2}
    /\ UNCHANGED <<version, phase, flight, flight_version, completed,
                    completed_values, candidate, corrupt, remaining, attempted, outcome>>
Enqueue3 ==
    /\ 3 \notin accepted
    /\ phase \notin {"copying", "ready"}
    /\ Outstanding < 2
    /\ queue' = Append(queue, 3) /\ accepted' = accepted \cup {3}
    /\ UNCHANGED <<version, phase, flight, flight_version, completed,
                    completed_values, candidate, corrupt, remaining, attempted, outcome>>
Start == /\ phase = "running" /\ flight = 0 /\ Len(queue) > 0
         /\ flight' = Head(queue) /\ queue' = Tail(queue)
         /\ flight_version' = version
         /\ UNCHANGED <<version, phase, accepted, completed, completed_values,
                         candidate, corrupt, remaining, attempted, outcome>>
Finish == /\ flight # 0
          /\ completed' = Append(completed, flight)
          /\ completed_values' = Append(completed_values, flight * 10)
          /\ flight' = 0 /\ flight_version' = 0
          /\ UNCHANGED <<version, phase, queue, accepted, candidate, corrupt,
                          remaining, attempted, outcome>>
Begin == /\ phase = "running" /\ version = 1 /\ ~attempted
         /\ phase' = "draining" /\ attempted' = TRUE
         /\ remaining' = 3 /\ outcome' = "pending"
         /\ UNCHANGED <<version, queue, flight, flight_version, accepted,
                         completed, completed_values, candidate, corrupt>>
Prepare == /\ phase = "draining" /\ flight = 0
           /\ phase' = "copying" /\ candidate' = <<>>
           /\ UNCHANGED <<version, queue, flight, flight_version, accepted,
                           completed, completed_values, corrupt, remaining, attempted, outcome>>
Copy == /\ phase = "copying" /\ Len(candidate) < Len(queue)
        /\ candidate' = Append(candidate, queue[Len(candidate) + 1])
        /\ UNCHANGED <<version, phase, queue, flight, flight_version, accepted,
                        completed, completed_values, corrupt, remaining, attempted, outcome>>
Corrupt == /\ phase \in {"copying", "ready"} /\ ~corrupt
           /\ corrupt' = TRUE
           /\ UNCHANGED <<version, phase, queue, flight, flight_version, accepted,
                           completed, completed_values, candidate, remaining, attempted, outcome>>
Refuse == /\ phase' = "running" /\ outcome' = "refused"
          /\ remaining' = 0 /\ candidate' = <<>> /\ corrupt' = FALSE
          /\ UNCHANGED <<version, queue, flight, flight_version, accepted,
                          completed, completed_values, attempted>>
Validate == /\ phase = "copying"
            /\ IF candidate = queue /\ ~corrupt
                  THEN /\ phase' = "ready"
                       /\ UNCHANGED <<version, queue, flight, flight_version, accepted,
                                       completed, completed_values, candidate, corrupt,
                                       remaining, attempted, outcome>>
                  ELSE Refuse
Activate == /\ phase = "ready"
            /\ IF candidate = queue /\ ~corrupt /\ flight = 0
                  THEN /\ version' = 2 /\ phase' = "running"
                       /\ outcome' = "activated" /\ remaining' = 0
                       /\ candidate' = <<>> /\ corrupt' = FALSE
                       /\ UNCHANGED <<queue, flight, flight_version, accepted,
                                       completed, completed_values, attempted>>
                  ELSE Refuse
Fail == /\ outcome = "pending" /\ Refuse
Tick == /\ outcome = "pending"
        /\ IF remaining > 1
              THEN /\ remaining' = remaining - 1
                   /\ UNCHANGED <<version, phase, queue, flight, flight_version, accepted,
                                   completed, completed_values, candidate, corrupt, attempted, outcome>>
              ELSE Refuse
Next == Enqueue1 \/ Enqueue2 \/ Enqueue3 \/ Start \/ Finish \/ Begin \/ Prepare
        \/ Copy \/ Corrupt \/ Validate \/ Activate \/ Fail \/ Tick
Spec == Init /\ [][Next]_vars /\ WF_vars(Tick)
Termination == (outcome = "pending") ~> (outcome # "pending")
TypeOK == /\ version \in {1, 2} /\ phase \in {"running", "draining", "copying", "ready"}
          /\ queue \in Seq(Ids) /\ flight \in Ids \cup {0}
          /\ flight_version \in {0, 1, 2} /\ accepted \subseteq Ids
          /\ completed \in Seq(Ids) /\ completed_values \in Seq({10, 20, 30})
          /\ candidate \in Seq(Ids) /\ corrupt \in BOOLEAN
          /\ remaining \in 0..3 /\ attempted \in BOOLEAN
          /\ outcome \in {"none", "pending", "activated", "refused"}
Conservation ==
    LET pending == Elements(queue)
        done == Elements(completed)
        active == IF flight = 0 THEN {} ELSE {flight}
    IN /\ accepted = pending \cup done \cup active
       /\ pending \cap done = {} /\ pending \cap active = {} /\ done \cap active = {}
       /\ Cardinality(pending) = Len(queue) /\ Cardinality(done) = Len(completed)
Safety == /\ TypeOK /\ Outstanding <= 2 /\ Conservation
          /\ Len(completed_values) = Len(completed)
          /\ \A i \in 1..Len(completed): completed_values[i] = completed[i] * 10
          /\ (IF flight = 0 THEN flight_version = 0 ELSE flight_version = version)
          /\ phase \in {"copying", "ready"} => flight = 0
          /\ (outcome = "pending") <=> (phase # "running")
          /\ (outcome = "pending") <=> (remaining > 0)
          /\ (version = 2) <=> (outcome = "activated")
          /\ ~attempted <=> (outcome = "none")
          /\ phase = "ready" => candidate = queue
          /\ candidate = SubSeq(queue, 1, Len(candidate))
          /\ phase \notin {"copying", "ready"} => (candidate = <<>> /\ ~corrupt)
=============================================================================
