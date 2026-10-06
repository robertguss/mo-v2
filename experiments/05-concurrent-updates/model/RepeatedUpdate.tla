---------------------------- MODULE RepeatedUpdate ----------------------------
EXTENDS Naturals, Sequences, FiniteSets
VARIABLES issued, pending, running, expired, committed, ignored, epoch
vars == <<issued, pending, running, expired, committed, ignored, epoch>>
Ids == {1,2}
Elements(s) == {s[i] : i \in 1..Len(s)}
Init == /\ issued = 0 /\ pending = 0 /\ running = {} /\ expired = {}
        /\ committed = <<>> /\ ignored = {} /\ epoch = 0
Begin1 == /\ pending = 0 /\ issued = 0
          /\ issued' = 1 /\ pending' = 1 /\ running' = running \cup {1}
          /\ UNCHANGED <<expired, committed, ignored, epoch>>
Begin2 == /\ pending = 0 /\ issued = 1
          /\ issued' = 2 /\ pending' = 2 /\ running' = running \cup {2}
          /\ UNCHANGED <<expired, committed, ignored, epoch>>
Timeout == /\ pending # 0 /\ expired' = expired \cup {pending}
           /\ pending' = 0
           /\ UNCHANGED <<issued, running, committed, ignored, epoch>>
Return1 == /\ 1 \in running /\ running' = running \ {1}
           /\ IF pending = 1
                 THEN /\ committed' = Append(committed,1) /\ epoch' = epoch+1
                      /\ pending' = 0 /\ UNCHANGED <<issued, expired, ignored>>
                 ELSE /\ ignored' = ignored \cup {1}
                      /\ UNCHANGED <<issued, pending, expired, committed, epoch>>
Return2 == /\ 2 \in running /\ running' = running \ {2}
           /\ IF pending = 2
                 THEN /\ committed' = Append(committed,2) /\ epoch' = epoch+1
                      /\ pending' = 0 /\ UNCHANGED <<issued, expired, ignored>>
                 ELSE /\ ignored' = ignored \cup {2}
                      /\ UNCHANGED <<issued, pending, expired, committed, epoch>>
Next == Begin1 \/ Begin2 \/ Timeout \/ Return1 \/ Return2
Spec == Init /\ [][Next]_vars /\ WF_vars(Timeout)
Termination == (pending # 0) ~> (pending = 0)
Safety == /\ issued \in 0..2 /\ pending \in 0..2
          /\ running \subseteq Ids /\ expired \subseteq Ids /\ ignored \subseteq Ids
          /\ committed \in Seq(Ids) /\ epoch \in 0..2
          /\ epoch = Len(committed)
          /\ Cardinality(Elements(committed)) = Len(committed)
          /\ \A i,j \in 1..Len(committed): i < j => committed[i] < committed[j]
          /\ expired \cap Elements(committed) = {}
          /\ pending # 0 => (pending \in running /\ pending \notin expired)
          /\ running \cup expired \cup ignored \cup Elements(committed) \subseteq 1..issued
          /\ pending <= issued
=============================================================================
