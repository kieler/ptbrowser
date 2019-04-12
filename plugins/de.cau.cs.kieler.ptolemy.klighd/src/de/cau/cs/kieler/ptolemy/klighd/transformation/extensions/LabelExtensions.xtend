/*
 * KIELER - Kiel Integrated Environment for Layout Eclipse RichClient
 *
 * http://www.informatik.uni-kiel.de/rtsys/kieler/
 * 
 * Copyright 2012 by
 * + Kiel University
 *   + Department of Computer Science
 *     + Real-Time and Embedded Systems Group
 * 
 * This code is provided under the terms of the Eclipse Public License (EPL).
 * See the file epl-v10.html for the license text.
 */
package de.cau.cs.kieler.ptolemy.klighd.transformation.extensions

import de.cau.cs.kieler.klighd.kgraph.KLabeledGraphElement
import de.cau.cs.kieler.klighd.kgraph.util.KGraphUtil

/**
 * Utility methods for handling labels used by the Ptolemy to KGraph transformation.
 * 
 * @author cds
 * @kieler.rating yellow 2012-07-10 KI-15 cmot, grh
 * 
 * @containsExtensions ptolemy
 */
class LabelExtensions {
    /**
     * Sets the name of the given element by setting the text of its first label.
     * 
     * @param element the element to be named.
     * @param name the name.
     */
    def setName(KLabeledGraphElement element, String name) {
        if (element.labels.empty) {
            KGraphUtil::createInitializedLabel(element)
        }
        
        element.labels.get(0).text = name
    }
    
    /**
     * Returns the name of the given element. Its name is assumed to be the text of its first label.
     * 
     * @param element the element whose name to return.
     * @return the element's name or the empty string if none could be found.
     */
    def String getName(KLabeledGraphElement element) {
        if (element.labels.empty) {
            return ""
        } else {
            return element.labels.get(0).text
        }
    }
}
