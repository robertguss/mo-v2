import Full.Proofs.Basic
import Full.Proofs.Invariance
import Full.Proofs.Correspondence
import Full.Proofs.Final
import Full.Proofs.Destruction
import Full.Proofs.TrialCompatibility

namespace Full.Proofs

theorem f4 : Statements.F4 := Final.f4_of_f1 f1

theorem l2 : Statements.L2 := l2_of_f1 f1

end Full.Proofs
