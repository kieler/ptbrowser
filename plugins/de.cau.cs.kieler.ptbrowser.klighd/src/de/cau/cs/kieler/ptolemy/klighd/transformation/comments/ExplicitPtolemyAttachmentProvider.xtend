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
import de.cau.cs.kieler.ptolemy.klighd.transformation.extensions.AnnotationExtensions
import de.cau.cs.kieler.ptolemy.klighd.transformation.extensions.LabelExtensions
import org.eclipse.elk.core.comments.IExplicitAttachmentProvider

import static de.cau.cs.kieler.ptolemy.klighd.transformation.util.TransformationConstants.*

/**
 * Extracts explicit attachments made between comments and actors in Ptolemy.
 * 
 * @author cds
 */
final class ExplicitPtolemyAttachmentProvider implements IExplicitAttachmentProvider<KNode, KNode> {
    
    @Inject extension AnnotationExtensions
    @Inject extension LabelExtensions
    
    override findExplicitAttachment(KNode comment) {
        // Retrieve some annotations and check if we have the required information
        val location = comment.getAnnotation(ANNOTATION_LOCATION)
        val relativeTo = location?.getAnnotation(ANNOTATION_RELATIVE_TO)
        val relativeToElementName = location?.getAnnotation(ANNOTATION_RELATIVE_TO_ELEMENT_NAME)

        if (relativeTo !== null
            && relativeToElementName !== null
            && relativeToElementName.value !== null
            && relativeToElementName.value.equals("entity")) {

            // Look for siblings of the comment node that have the correct name
            for (sibling : comment.parent.children) {
                if (sibling.name.equals(relativeTo.value)) {
                    return sibling
                }
            }
        }
        
        return null
    }
    
}