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

import com.google.inject.Inject
import de.cau.cs.kieler.ptolemy.klighd.transformation.util.TransformationConstants
import org.eclipse.elk.core.options.CoreOptions

import static de.cau.cs.kieler.ptolemy.klighd.transformation.util.TransformationConstants.*
import com.google.common.base.Strings
import de.cau.cs.kieler.klighd.kgraph.KGraphElement
import de.cau.cs.kieler.klighd.kgraph.KEdge
import de.cau.cs.kieler.klighd.kgraph.KNode

/**
 * Utility methods used to mark elements by the Ptolemy to KGraph transformation.
 * 
 * @author cds
 * @kieler.rating yellow 2012-07-10 KI-15 cmot, grh
 * 
 * @containsExtensions ptolemy
 */
class MarkerExtensions {
    /** We make use of annotations to mark stuff. */
    @Inject extension AnnotationExtensions
    
    
    /**
     * Marks the given KGraph element as originating from a Ptolemy model.
     * 
     * @param element the element to mark.
     */
    def void markAsPtolemyElement(KGraphElement element) {
        addAnnotation(element, ANNOTATION_LANGUAGE, ANNOTATION_LANGUAGE_PTOLEMY)
    }
    
    /**
     * Marks the given edge as being undirected. This means that the link's direction has not been
     * inferred yet.
     * 
     * @param edge the edge to mark.
     * @param mark {@code true} if the edge should be marked as being undirected, {@code false} if the
     *             marking should be removed.
     */
    def void markAsUndirected(KEdge edge, boolean mark) {
        if (mark) {
            edge.addAnnotation("_undirected")
        } else {
            edge.removeAnnotation("_undirected")
        }
    }
    
    /**
     * Checks if the given edge is marked as being undirected.
     * 
     * @param edge the edge to check.
     * @return {@code true} if the edge is marked as undirected, {@code false} otherwise.
     */
    def boolean isMarkedAsUndirected(KEdge edge) {
        return edge.hasAnnotation("_undirected")
    }
    
    /**
     * Marks the given port as being an input port.
     * 
     * @param port the port to mark.
     * @param mark {@code true} if the port should be marked, {@code false} if the marking should be
     *             removed.
     */
    def void markAsInputPort(KGraphElement port, boolean mark) {
        if (mark) {
            port.addAnnotation("_input")
        } else {
            port.removeAnnotation("_input")
        }
    }
    
    /**
     * Checks if the given port is marked as being an input port.
     * 
     * @param port the port to check.
     * @return {@code true} if the port is marked as being an input port, {@code false} otherwise.
     */
    def boolean isMarkedAsInputPort(KGraphElement port) {
        return port.hasAnnotation("_input")
    }
    
    /**
     * Marks the given port as being an output port.
     * 
     * @param port the port to mark.
     * @param mark {@code true} if the port should be marked, {@code false} if the marking should be
     *             removed.
     */
    def void markAsOutputPort(KGraphElement port, boolean mark) {
        if (mark) {
            port.addAnnotation("_output")
        } else {
            port.removeAnnotation("_output")
        }
    }
    
    /**
     * Checks if the given port is marked as being an output port.
     * 
     * @param port the port to check.
     * @return {@code true} if the port is marked as being an output port, {@code false} otherwise.
     */
    def boolean isMarkedAsOutputPort(KGraphElement port) {
        return port.hasAnnotation("_output")
    }
    
    /**
     * Marks a node as formerly having been an annotation. Some nodes do not map to actors in the
     * original Ptolemy model, but to annotations. For example, the director used to execute a model
     * is persisted as an annotation in Ptolemy. In the corresponding KGraph model, we need it to be a
     * node to display it correctly.
     * 
     * @param node the node to mark.
     */
    def void markAsFormerAnnotationNode(KNode node) {
        node.addAnnotation("_annotationNode")
    }
    
    /**
     * Checks if the given node is marked as having been created from an annotation.
     * 
     * @param node the node to check.
     * @return {@code true} if it is marked, {@code false} otherwise.
     */
    def boolean isMarkedAsFormerAnnotationNode(KNode node) {
        return node.hasAnnotation("_annotationNode")
    }
    
    /**
     * Marks the given node as being a hypernode.
     * 
     * @param node the node to be marked.
     */
    def void markAsHypernode(KNode node) {
        node.setProperty(CoreOptions::HYPERNODE, true)
    }
    
    /**
     * Checks if the given node is marked as being a hypernode.
     * 
     * @param node the node to check.
     * @return {@code true} if the node is marked as being a hypernode, {@code false} otherwise.
     */
    def boolean isMarkedAsHypernode(KNode node) {
        return node.getProperty(CoreOptions::HYPERNODE)
    }
    
    /**
     * Marks the given node as being a comment node.
     * 
     * @param node the node to be marked.
     */
    def void markAsComment(KNode node) {
        node.setProperty(CoreOptions::COMMENT_BOX, true)
    }
    
    /**
     * Checks if the given node is marked as being a comment node.
     * 
     * @param node the node to check.
     * @return {@code true} if the node is marked as being a comment node, {@code false} otherwise.
     */
    def boolean isMarkedAsComment(KNode node) {
        return node.getProperty(CoreOptions::COMMENT_BOX)
    }
    
    /**
     * Marks the given node as containing a state machine.
     * 
     * @param node the node to be marked.
     */
    def void markAsStateMachineContainer(KNode node) {
        node.addAnnotation("_stateMachineContainer")
    }
    
    /**
     * Checks if the given node is marked as containing a state machine.
     * 
     * @param node the node to check.
     * @return {@code true} if the node is marked as containing a state machine, {@code false}
     *         otherwise.
     */
    def boolean isMarkedAsStateMachineContainer(KNode node) {
        return node.hasAnnotation("_stateMachineContainer")
    }
    
    /**
     * Marks the given node as being a director node.
     * 
     * @param node the node to be marked.
     */
    def void markAsDirector(KNode node) {
        node.addAnnotation("_director")
    }
    
    /**
     * Checks if the given node is marked as being a director node.
     * 
     * @param node the node to check.
     * @return {@code true} if the node is a director node.
     */
    def boolean isMarkedAsDirector(KNode node) {
        return node.hasAnnotation("_director")
    }
    
    /**
     * Marks the given node as being a title node. A title node is a special node that contains the 
     * title of a diagram.
     * 
     * @param node the node to be marked
     */
    def void markAsTitleNode(KNode node){
        node.addAnnotation("_titleNode")
    }
    
    /**
     * Checks if the given node is marked as being a title node. A title node is a special node that
     * contains the title of a diagram.
     * 
     * @param node the node to check
     */ 
    def boolean isMarkedAsTitleNode(KNode node){
        return node.hasAnnotation("_titleNode")
    }
    
    /**
     * Marks the given node as being a parameter node that displays model parameters.
     * 
     * @param node the node to be marked.
     */
    def void markAsParameterNode(KNode node) {
        node.addAnnotation("_parameters")
    }
    
    /**
     * Checks if the given node is marked as being a parameter node.
     * 
     * @param node the node to check.
     * @return {@code true} if the node is a parameter node.
     */
    def boolean isMarkedAsParameterNode(KNode node) {
        return node.hasAnnotation("_parameters")
    }
    
    /**
     * Marks the given node as being a documentation attribute node that contains documentation.
     * 
     * @param node the node to be marked.
     */
    def void markAsDocumentationNode(KNode node) {
        node.addAnnotation("_documentation")
    }
    
     /**
     * Checks if the given node is marked as being a documentation attribute node.
     * 
     * @param node the node to check.
     * @return {@code true} if the node is a documentation attribute node.
     */
    def boolean isMarkedAsDocumentationNode(KNode node) {
        return node.hasAnnotation("_documentation")
    }
    
    /**
     * Checks if the given node has a state refinement.
     * 
     * @param node the node to check.
     * @return {@code true} if the node has a refinement.
     */
    def boolean isMarkedAsHavingRefinement(KNode node) {
        return !(node.getAnnotationValue(ANNOTATION_REFINEMENT_NAME).nullOrEmpty)
    }
    
    /**
     * Checks if the given node is a value displaying actor, for instance a Const actor.
     * 
     * @param node the node to check.
     * @return {@code true} if the node represents a value displaying actor.
     */
    def boolean isMarkedAsValueDisplayingActor(KNode node) {
        val propertyValue = Strings.nullToEmpty(node.getAnnotationValue(ANNOTATION_PTOLEMY_CLASS))
        return TransformationConstants.VALUE_DISPLAY_MAP.keySet().contains(propertyValue)
    }
    
    /**
     * Checks if the given node is a Ptolemy state machine model state.
     * 
     * @param node the node to check.
     * @return {@code true} if the node represents a state.
     */
    def boolean isMarkedAsState(KNode node) {
        val propertyValue = Strings.nullToEmpty(node.getAnnotationValue(ANNOTATION_PTOLEMY_CLASS))
        return propertyValue.equals(ENTITY_CLASS_STATE) || propertyValue.equals(ENTITY_CLASS_FSM_STATE)
    }
    
    /**
     * Marks the given node as representing a modal model port by setting its Ptolemy class accordingly.
     * 
     * @param node the node to be marked.
     */
    def void markAsModalModelPort(KNode node) {
        node.addAnnotation(ANNOTATION_PTOLEMY_CLASS, PORT_CLASS_REFINEMENT_PORT)
    }
    
    /**
     * Checks if the given node or port is a state machine model port. These ports need to be turned
     * into nodes that can have a special rendering, like in Ptolemy.
     * 
     * @param element the element to check.
     * @return {@code true} if the element represents a modal model port.
     */
    def boolean isMarkedAsModalModelPort(KGraphElement element) {
        val propertyValue = Strings.nullToEmpty(element.getAnnotationValue(ANNOTATION_PTOLEMY_CLASS))
        return propertyValue.equals(PORT_CLASS_REFINEMENT_PORT)
            || propertyValue.equals(PORT_CLASS_FSM_REFINEMENT_PORT)
    }
    
}
