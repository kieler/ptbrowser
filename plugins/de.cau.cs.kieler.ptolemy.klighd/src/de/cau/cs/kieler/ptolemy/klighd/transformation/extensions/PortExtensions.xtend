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

import static de.cau.cs.kieler.ptolemy.klighd.transformation.util.TransformationConstants.*

/**
 * Utility methods for coping with ports used by the Ptolemy to KGraph transformation.
 * 
 * @author cds
 * @kieler.rating yellow 2012-07-10 KI-15 cmot, grh
 * 
 * @containsExtensions
 */
class PortExtensions {
    
    /**
     * Checks if the given name is a name usual for input ports.
     * 
     * @param name the name of the port to check.
     * @return {@code true} if the name is common for input ports, {@code false} otherwise.
     */
    def boolean isInputPortName(String name) {
        for (String inputPortName : PORT_NAMES_INPUT) {
            if (inputPortName.equals(name)) {
                return true
            }
        }
        
        return false
    }
    
    /**
     * Checks if the given name is a name usual for output ports.
     * 
     * @param name the name of the port to check.
     * @return {@code true} if the name is common for output ports, {@code false} otherwise.
     */
    def boolean isOutputPortName(String name) {
        for (String inputPortName : PORT_NAMES_OUTPUT) {
            if (inputPortName.equals(name)) {
                return true
            }
        }
        
        return false
    }
    
}
