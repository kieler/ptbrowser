/*
 * KIELER - Kiel Integrated Environment for Layout Eclipse RichClient
 *
 * http://rtsys.informatik.uni-kiel.de/kieler
 * 
 * Copyright 2015 by
 * + Kiel University
 *   + Department of Computer Science
 *     + Real-Time and Embedded Systems Group
 * 
 * This code is provided under the terms of the Eclipse Public License (EPL).
 */
package de.cau.cs.kieler.ptolemy.klighd;

/**
 * Defines several ways of displaying port labels in the Ptolemy viewer.
 * 
 * @author cds
 */
public enum LabelDisplayStyle {
    
    /** Port labels are displayed for all ports. */
    ALL("All"),
    /** Port labels are only displayed for the currently selected node. */
    SELECTED("Selected"),
    /** No port labels are displayed. */
    NONE("None");
    
    
    /** How this instance will be advertised in the UI. */
    private String displayString;
    
    
    /**
     * Creates a new instance that maps to the given display string.
     * 
     * @param s the display string.
     */
    private LabelDisplayStyle(String s) {
        displayString = s;
    }

    
    /**
     * Returns the port label display style represented by the given display string.
     * 
     * @param ds the display string.
     * @return the port label display style, or {@code null} if none could be found.
     */
    public static LabelDisplayStyle fromDisplayString(String ds) {
        for (LabelDisplayStyle style : LabelDisplayStyle.values()) {
            if (style.toString().equalsIgnoreCase(ds)) {
                return style;
            }
        }
        if (ds.equalsIgnoreCase("false")) {
            return NONE;
        }
        return null;
    }
    
    @Override
    public String toString() {
        return displayString;
    }
    
}
