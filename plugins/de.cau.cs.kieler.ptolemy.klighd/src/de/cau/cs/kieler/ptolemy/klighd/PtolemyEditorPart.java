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

import java.util.Map;

import org.eclipse.emf.ecore.resource.ResourceSet;
import org.eclipse.emf.ecore.xmi.XMIResource;
import org.eclipse.emf.ecore.xmi.XMLResource;
import org.ptolemy.moml.util.MomlResourceFactoryImpl;

import com.google.common.collect.Maps;

import de.cau.cs.kieler.klighd.ui.parts.DiagramEditorPart;

/**
 * Editor part for displaying Ptolemy models in a KLighD viewer. The editor part disables certain EMF
 * loading checks and stuff.
 * 
 * @author uru
 * @author cds
 * @kieler.rating proposed yellow cds 2015-02-23
 */
public class PtolemyEditorPart extends DiagramEditorPart {

    /**
     * Map containing a standard list of parser features used for loading EMF resources.
     */
    private Map<String, Boolean> parserFeatures = null;

    /**
     * Create a new editor part for displaying a Ptolemy model.
     */
    public PtolemyEditorPart() {
        // Prepare parser feature map. These options avoid searching for DTDs online, which would
        // require an internet connection to load models
        parserFeatures = Maps.newHashMap();
        parserFeatures.put(
                "http://xml.org/sax/features/validation", //$NON-NLS-1$
                Boolean.FALSE);
        parserFeatures.put(
                "http://apache.org/xml/features/nonvalidating/load-dtd-grammar", //$NON-NLS-1$
                Boolean.FALSE);
        parserFeatures.put(
                "http://apache.org/xml/features/nonvalidating/load-external-dtd", //$NON-NLS-1$
                Boolean.FALSE);
    }

    
    @Override
    protected void configureResourceSet(ResourceSet set) {
        set.getLoadOptions().put(XMIResource.OPTION_RECORD_UNKNOWN_FEATURE, true);
        set.getLoadOptions().put(XMLResource.OPTION_PARSER_FEATURES, parserFeatures);
        set.getResourceFactoryRegistry().getExtensionToFactoryMap()
                .put("xml", new MomlResourceFactoryImpl());
    }

}