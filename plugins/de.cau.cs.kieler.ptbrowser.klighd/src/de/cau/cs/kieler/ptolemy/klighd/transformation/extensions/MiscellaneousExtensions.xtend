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
import de.cau.cs.kieler.klighd.krendering.KPosition
import de.cau.cs.kieler.klighd.krendering.KRenderingFactory
import java.util.List
import org.eclipse.emf.ecore.EObject
import org.ptolemy.moml.ClassType
import org.ptolemy.moml.EntityType

import static de.cau.cs.kieler.ptolemy.klighd.transformation.util.TransformationConstants.*

import static extension com.google.common.base.Strings.*
import de.cau.cs.kieler.klighd.kgraph.KPort
import de.cau.cs.kieler.klighd.kgraph.KEdge
import de.cau.cs.kieler.klighd.kgraph.KNode

/**
 * Utility methods used by the Ptolemy to KGraph transformation.
 * 
 * @author cds
 * @kieler.rating yellow 2012-07-10 KI-15 cmot, grh
 * 
 * @containsExtensions
 */
class MiscellaneousExtensions {
    /** Access to annotations. */
    @Inject extension AnnotationExtensions
    /** We're using markers for some of this stuff. */
    @Inject extension MarkerExtensions
    
    
    /**
     * Checks if the given port has an incident edge of unknown direction.
     * 
     * @param port the port to check.
     * @return {@code true} if the port has an incident edge of unknown direction,
     *         {@code false} otherwise.
     */
    def boolean hasUnknownIncidentEdge(KPort port) {
        for (edge : port.edges) {
            if (edge.isMarkedAsUndirected()) {
                return true
            }
        }
        
        return false
    }
    
    /**
     * Reverses the given edge's direction.
     * 
     * @param edge the edge to reverse.
     */
    def void reverseEdge(KEdge edge) {
        val oldSource = edge.source
        val oldSourcePort = edge.sourcePort
        val oldTarget = edge.target
        val oldTargetPort = edge.targetPort
        
        edge.source = oldTarget
        edge.sourcePort = oldTargetPort
        edge.target = oldSource
        edge.targetPort = oldSourcePort
    }
    
    /**
     * Returns the first edge in the list that is marked as having a fixed direction.
     * 
     * @param edges list of edges to check for directed edges.
     * @return the first edge of known direction that is found or {@code null} if none could be found.
     */
    def KEdge getFirstDirectedEdge(Iterable<KEdge> edges) {
        for (edge : edges) {
            if (!edge.isMarkedAsUndirected()) {
                return edge
            }
        }
        
        return null
    }
    
    /**
     * Returns a list of all edges incident to the given node.
     * 
     * @param node the node whose incident edges to return.
     * @return a list of all incident edges.
     */
    def List<KEdge> getIncidentEdges(KNode node) {
        val List<KEdge> incidentEdges = newArrayList()
        
        incidentEdges.addAll(node.incomingEdges)
        incidentEdges.addAll(node.outgoingEdges)
        
        return incidentEdges
    }
    
    /**
     * Given a modal model state, tries to find the entity that represents its refinement, if any.
     * 
     * @param ptState the modal model state.
     * @return the entity that defines its refinement, or {@code null} if there is none or if none could
     *         be found.
     */
    def EntityType findRefinement(EObject ptState) {
        /* Let's take a short break and meditate over what exactly will be going on in this method.
         * First, everything that happens requires the container of the state to be a modal model
         * controller. At the time of writing, modal models were the only models that allowed states
         * to be refined. The structure in modal models is as follows:
         * 
         *    Entity (class "ptolemy.domains.modal.modal.ModalModel")
         *        Entity "_Controller" (class "ptolemy.domains.modal.modal.ModalController")
         *            State entities
         *                Property "refinementName" (this points to the name of an entity defined under
         *                                           the modal model entity)
         *        Refinement entities (class usually "ptolemy.domains.modal.modal.Refinement"
         *                                        or "ptolemy.domains.modal.modal.ModalController")
         * 
         * The algorithm basically checks if a refinement name is defined for the given state. If so,
         * it looks in the modal model entity for a refinement entity of the given name and returns
         * that. The algorithm checks along the way if the class names are what we expect them to be.
         */
        
        val refinementName = ptState.getAnnotationValue(ANNOTATION_REFINEMENT_NAME)
        
        if (!refinementName.nullOrEmpty) {
            // We can only do something if the state's container is a modal model controller; if not,
            // we have no idea which kind of structure we are in
            val containerClass = if (ptState.eContainer instanceof EntityType) {
                (ptState.eContainer as EntityType).class1.nullToEmpty
            } else if (ptState.eContainer instanceof ClassType) {
                (ptState.eContainer as ClassType).^extends.nullToEmpty
            }
            
            if (containerClass.equals(ENTITY_CLASS_MODEL_CONTROLLER)
                || containerClass.equals(ENTITY_CLASS_FSM_MODEL_CONTROLLER)) {
                
                // The container's container should be the modal model entity
                val modalModel = ptState.eContainer.eContainer
                
                // Check if the modal model container's type is what we'd expect
                val modalModelClass = if (modalModel instanceof EntityType) {
                    (modalModel as EntityType).class1.nullToEmpty
                } else if (modalModel instanceof ClassType) {
                    (modalModel as ClassType).^extends.nullToEmpty
                }
                
                if (modalModelClass.equals(ENTITY_CLASS_MODAL_MODEL)
                    || modalModelClass.equals(ENTITY_CLASS_FSM_MODAL_MODEL)) {
                        
                    // Look for entities with the given name
                    val childEntities = if (modalModel instanceof EntityType) {
                        (modalModel as EntityType).entity
                    } else if (modalModel instanceof ClassType) {
                        (modalModel as ClassType).entity
                    }
                    
                    if (childEntities !== null) {
                        return childEntities.findFirst([child | child.name.equals(refinementName)])
                    }
                }
            }
        }
        
        // We couldn't find a refinement
        return null
    }
    
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////
    // KRendering Utility Methods
    
    /**
     * Creates a position with the given absolute x and y coordinates.
     * 
     * @param x the x coordinate.
     * @param y the y coordinate.
     * @return KPosition representing the given absolut coordinates.
     */
    def KPosition createKPosition(float x, float y) {
        val xPos = KRenderingFactory::eINSTANCE.createKLeftPosition()
        xPos.absolute = x
        
        val yPos = KRenderingFactory::eINSTANCE.createKTopPosition()
        yPos.absolute = y
        
        val pos = KRenderingFactory::eINSTANCE.createKPosition()
        pos.x = xPos
        pos.y = yPos
        
        return pos
    }
}
