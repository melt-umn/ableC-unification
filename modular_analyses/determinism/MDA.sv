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

parser ableCWithPatternMatching :: Root {
  edu:umn:cs:melt:ableC:concretesyntax;
  edu:umn:cs:melt:exts:ableC:algebraicDataTypes:patternmatching:concretesyntax;
}

copper_mda testPatternMatching(ableCWithPatternMatching) {
  edu:umn:cs:melt:exts:ableC:unification:concretesyntax:patternmatching;
}

