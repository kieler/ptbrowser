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
package de.cau.cs.kieler.ptolemy.klighd.transformation.comments

import com.google.inject.Inject
import de.cau.cs.kieler.klighd.kgraph.KNode
import de.cau.cs.kieler.klighd.microlayout.PlacementUtil
import de.cau.cs.kieler.ptolemy.klighd.transformation.extensions.AnnotationExtensions
import de.cau.cs.kieler.ptolemy.klighd.transformation.extensions.MarkerExtensions
import java.awt.geom.Rectangle2D
import org.eclipse.elk.core.comments.IBoundsProvider

import static de.cau.cs.kieler.ptolemy.klighd.PtolemyProperties.*
import static de.cau.cs.kieler.ptolemy.klighd.transformation.util.TransformationConstants.*

/**
 * Retrieves the position of the given node in the original Ptolemy diagram, if any, as well as
 * its size as given by the node's shape layout. The shape layout's size fields are expected to
 * have been correctly set during the visualization step of the diagram synthesis. It's a good
 * idea to wrap this bounds provider in a caching bounds provider prior to use, as calculating
 * bounds for Ptolemy objects can be quite expensive.
 * 
 * @author cds
 */
final class PtolemyBoundsProvider implements IBoundsProvider<KNode, KNode> {
    
    @Inject extension AnnotationExtensions
    @Inject extension MarkerExtensions
    
    
    override boundsForComment(KNode comment) {
        return boundsFor(comment);
    }
    
    override boundsForTarget(KNode target) {
        return boundsFor(target);
    }
    
    /**
     * Returns the bounds for the given node, wheter it's a comment or not.
     */
    private def boundsFor(KNode node) {
        val bounds = new Rectangle2D.Double();
        
        // Initialize point with ridiculous values
        bounds.x = 2e20;
        bounds.y = 2e20;

        // Get location annotation
        var locationAnnotation = node.getAnnotation(ANNOTATION_LOCATION);
        var String locationAnnotationValue;

        if (locationAnnotation === null) {
            var locationSpecialAnnotation = node.getProperty(PT_LOCATION);
            if (locationSpecialAnnotation === null) {
                return bounds;
            } else {
                locationAnnotationValue = locationSpecialAnnotation;
            }
        } else {
            locationAnnotationValue = locationAnnotation.value;
        }

        // Try parsing the location information by splitting the string into an array of components.
        // Locations have one of the following three representations:
        //   "[140.0, 20.0]"     "{140.0, 20.0}"     "140.0, 20.0"
        // We remove all braces and whitespace and split at the comma that remains.
        val locationString = locationAnnotationValue.replaceAll("[\\s\\[\\]{}]+", "");
        val locationArray = locationString.split(",");

        if (locationArray.size == 2) {
            try {
                bounds.x = Double::valueOf(locationArray.get(0));
                bounds.y = Double::valueOf(locationArray.get(1));

                // Save the node's size in the bounds as well
                val estimatedSize = PlacementUtil.estimateSize(node);

                bounds.width = estimatedSize.width;
                bounds.height = estimatedSize.height;
            } catch (NumberFormatException e) {
                // We can't really do anything about this
            }
        }

        // The location defines where an actor's anchor point is. Where the anchor point is positioned
        // in the actor is a completely different question and defaults to the actor's center, except
        // for TextAttribute instances, which default to northwest.
        val anchorDefault =
            if (node.markedAsComment) {
                "northwest";
            } else {
                "center";
            };
        val anchorAnnotation = node.getAnnotation(ANNOTATION_ANCHOR);
        val anchorString = anchorAnnotation?.value ?: anchorDefault;

        switch (anchorString) {
            case "north": {
                bounds.x = bounds.y - bounds.width / 2;
            }
            case "south": {
                bounds.x = bounds.x - bounds.width / 2;
                bounds.y = bounds.y - bounds.height;
            }
            case "west": {
                bounds.y = bounds.y - bounds.height / 2;
            }
            case "east": {
                bounds.x = bounds.x - bounds.width;
                bounds.y = bounds.y - bounds.height / 2;
            }
            case "northwest": {
                // Nothing to do
            }
            case "northeast": {
                bounds.x = bounds.x - bounds.width;
            }
            case "southwest": {
                bounds.y = bounds.y - bounds.height;
            }
            case "sountheast": {
                // Ptolemy has a typo here; we support this typo as well as the correct spelling
                bounds.x = bounds.x - bounds.width;
                bounds.y = bounds.y - bounds.height;
            }
            case "southeast": {
                bounds.x = bounds.x - bounds.width;
                bounds.y = bounds.y - bounds.height;
            }
            default: {
                bounds.x = bounds.x - bounds.width / 2;
                bounds.y = bounds.y - bounds.height / 2;
            }
        }
        
        return bounds;
    }
    
}