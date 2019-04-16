/*
 * KIELER - Kiel Integrated Environment for Layout Eclipse RichClient
 *
 * http://www.informatik.uni-kiel.de/rtsys/kieler/
 * 
 * Copyright 2013 by
 * + Kiel University
 *   + Department of Computer Science
 *     + Real-Time and Embedded Systems Group
 * 
 * This code is provided under the terms of the Eclipse Public License (EPL).
 * See the file epl-v10.html for the license text.
 */
package de.cau.cs.kieler.ptolemy.klighd;

import java.util.ArrayList;
import java.util.List;

import org.eclipse.elk.core.util.Pair;
import org.eclipse.elk.graph.properties.IProperty;
import org.eclipse.elk.graph.properties.Property;
import org.ptolemy.moml.PropertyType;

/**
 * Properties used when representing Ptolemy models as KGraphs.
 * 
 * @author cds
 * @kieler.rating proposed yellow cds 2015-02-23
 */
public final class PtolemyProperties {
    /**
     * Properties of the original Ptolemy object a KGraph element was created from. Such properties are
     * saved as a property with a list instead of being converted to first-class properties. This is
     * mainly because we don't know in advance which kinds of properties Ptolemy objects can have, and
     * because properties can have properties themselves.
     */
    public static final IProperty<List<PropertyType>> PT_PROPERTIES =
            new Property<List<PropertyType>>("ptolemy.properties", new ArrayList<PropertyType>());
    
    /**
     * The text a comment node should display.
     */
    public static final IProperty<String> COMMENT_TEXT = new Property<String>("comment.text", null);
    
    /**
     * The location of a property that is transformed into a node.
     */
    public static final IProperty<String> PT_LOCATION = new Property<String>("property.location", null);
    
    /**
     * The text size configured for a comment inside Ptolemy. Ptolemy's standard font size is 14.
     */
    public static final IProperty<Integer> COMMENT_FONT_SIZE = new Property<Integer>(
            "comment.fontSize", 14);
    
    /**
     * The parameters a parameter node should display. This is a list of pairs of Strings, each
     * containing the name and the value of a parameter.
     */
    public static final IProperty<List<Pair<String, String>>> PT_PARAMETERS =
            new Property<List<Pair<String, String>>>("ptolemy.parameters", null);
    
    /**
     * The parameters a parameter node should display. Those parameters are its name and value.
     */
    public static final IProperty<Pair<String,String>> PARAMETER_PAIR = 
            new Property<Pair<String,String>>("ptolemy.parameter", null);
  
    
    /**
     * This class is not to be instantiated.
     */
    private PtolemyProperties() {
        
    }
}
