/*
 * KIELER - Kiel Integrated Environment for Layout Eclipse RichClient
 *
 * http://rtsys.informatik.uni-kiel.de/kieler
 * 
 * Copyright 2016 by
 * + Kiel University
 *   + Department of Computer Science
 *     + Real-Time and Embedded Systems Group
 * 
 * This code is provided under the terms of the Eclipse Public License (EPL).
 */
package de.cau.cs.kieler.ptolemy.klighd.transformation.comments;

import java.util.Map;

import org.eclipse.elk.core.comments.DistanceMatcher;
import org.eclipse.elk.core.comments.IDecider;
import org.eclipse.elk.core.comments.IMatcher;
import org.eclipse.elk.core.comments.NodeReferenceMatcher;

import de.cau.cs.kieler.klighd.kgraph.KNode;

/**
 * An attachment decider that prefers to attach comments to nodes they mention.
 * 
 * @author cds
 */
public class ReferencePreferringAttachmentDecider implements IDecider<KNode> {

    @Override
    public KNode makeAttachmentDecision(
            Map<KNode, Map<Class<? extends IMatcher<?, KNode>>, Double>> normalizedHeuristics) {
        
        double bestResult = 0;
        KNode bestCandidate = null;
        
        for (Map.Entry<KNode, Map<Class<? extends IMatcher<?, KNode>>, Double>> candidate :
            normalizedHeuristics.entrySet()) {
            
            // If the node reference heuristic produced something worthwhile, use this node
            Double referenceValue = candidate.getValue().get(NodeReferenceMatcher.class);
            if (referenceValue != null && referenceValue > 0) {
                return candidate.getKey();
            }
            
            // Use the distance heuristic
            referenceValue = candidate.getValue().get(DistanceMatcher.class);
            if (referenceValue != null && referenceValue > bestResult) {
                bestResult = referenceValue;
                bestCandidate = candidate.getKey();
            }
        }
        
        return bestCandidate;
    }

}
