grammar determinism;

{- This Silver specification does not generate a useful working 
   compiler, it only serves as a grammar for running the modular
   determinism analysis.
 -}

import edu:umn:cs:melt:ableC:concretesyntax;
import edu:umn:cs:melt:ableC:host;

copper_mda testUnification(ablecParser) {
  edu:umn:cs:melt:exts:ableC:unification:concretesyntax:unification;
}

copper_mda testAllocation(ablecParser) {
  edu:umn:cs:melt:exts:ableC:unification:concretesyntax:allocation;
}

-- Since unification is an extension (E2) to a nonterminal introduced by another
-- extension (E1), we must perform the MDA with respect to a "host" language
-- containing the syntax being extended (H + E1).
-- TODO: Technically we should also be testing the composed (E1 + E2) against H,
-- but that isn't currently possible because E2's bridge productions don't
-- appear as such in (E1 + E2), resulting in marking terminals on non-bridge
-- productions.
parser ableCWithPatternMatching :: Root {
  edu:umn:cs:melt:ableC:concretesyntax;
  edu:umn:cs:melt:exts:ableC:algebraicDataTypes:patternmatching:concretesyntax;
}

copper_mda testPatternMatching(ableCWithPatternMatching) {
  edu:umn:cs:melt:exts:ableC:unification:concretesyntax:patternmatching;
}

