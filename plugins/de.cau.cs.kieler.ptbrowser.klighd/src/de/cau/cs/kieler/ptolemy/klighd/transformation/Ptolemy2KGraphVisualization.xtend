/*
 * KIELER - Kiel Integrated Environment for Layout Eclipse RichClient
 *
 * http://rtsys.informatik.uni-kiel.de/kieler
 * 
 * Copyright 2013-2022 by
 * + Kiel University
 *   + Department of Computer Science
 *     + Real-Time and Embedded Systems Group
 * 
 * This code is provided under the terms of the Eclipse Public License (EPL).
 * See the file epl-v10.html for the license text.
 */
package de.cau.cs.kieler.ptolemy.klighd.transformation

import com.google.common.base.Strings
import com.google.inject.Inject
import de.cau.cs.kieler.klighd.KlighdConstants
import de.cau.cs.kieler.klighd.actions.FocusAndContextAction
import de.cau.cs.kieler.klighd.kgraph.KEdge
import de.cau.cs.kieler.klighd.kgraph.KGraphElement
import de.cau.cs.kieler.klighd.kgraph.KLabeledGraphElement
import de.cau.cs.kieler.klighd.kgraph.KNode
import de.cau.cs.kieler.klighd.kgraph.KPort
import de.cau.cs.kieler.klighd.kgraph.KShapeLayout
import de.cau.cs.kieler.klighd.krendering.KAreaPlacementData
import de.cau.cs.kieler.klighd.krendering.KRendering
import de.cau.cs.kieler.klighd.krendering.KRenderingRef
import de.cau.cs.kieler.klighd.krendering.Trigger
import de.cau.cs.kieler.klighd.krendering.extensions.KContainerRenderingExtensions
import de.cau.cs.kieler.klighd.krendering.extensions.KRenderingExtensions
import de.cau.cs.kieler.klighd.microlayout.PlacementUtil
import de.cau.cs.kieler.klighd.syntheses.DiagramSyntheses
import de.cau.cs.kieler.klighd.util.ExpansionAwareLayoutOption
import de.cau.cs.kieler.klighd.util.KlighdProperties
import de.cau.cs.kieler.ptolemy.klighd.PtolemyDiagramSynthesis.Options
import de.cau.cs.kieler.ptolemy.klighd.transformation.extensions.AnnotationExtensions
import de.cau.cs.kieler.ptolemy.klighd.transformation.extensions.LabelExtensions
import de.cau.cs.kieler.ptolemy.klighd.transformation.extensions.MarkerExtensions
import de.cau.cs.kieler.ptolemy.klighd.transformation.extensions.MiscellaneousExtensions
import de.cau.cs.kieler.ptolemy.klighd.transformation.util.TransformationConstants
import java.util.EnumSet
import org.eclipse.elk.alg.layered.options.LayeredOptions
import org.eclipse.elk.core.math.KVector
import org.eclipse.elk.core.options.CoreOptions
import org.eclipse.elk.core.options.Direction
import org.eclipse.elk.core.options.EdgeLabelPlacement
import org.eclipse.elk.core.options.EdgeRouting
import org.eclipse.elk.core.options.NodeLabelPlacement
import org.eclipse.elk.core.options.PortConstraints
import org.eclipse.elk.core.options.PortLabelPlacement
import org.eclipse.elk.core.options.PortSide
import org.eclipse.elk.core.options.SizeConstraint

import static de.cau.cs.kieler.ptolemy.klighd.transformation.util.TransformationConstants.*
import de.cau.cs.kieler.ptolemy.klighd.LabelDisplayStyle

/**
 * Enriches a KGraph model freshly transformed from a Ptolemy2 model with the KRendering information
 * necessary to properly display the model. This is the final step of the Ptolemy model import process.
 * 
 * @author cds
 */
class Ptolemy2KGraphVisualization {
    
    /** Access to annotations. */
    @Inject extension AnnotationExtensions
    /** Access to labels. */
    @Inject extension LabelExtensions
    /** Access to marked nodes. */
    @Inject extension MarkerExtensions
    /** Extensions used during the transformation. To make things easier. And stuff. */
    @Inject extension MiscellaneousExtensions
    /** Utility class that provides renderings. */
    @Inject extension KRenderingExtensions
    /** Utility class that provides renderings. */
    @Inject extension KContainerRenderingExtensions
    /** Utility class that provides renderings. */
    @Inject extension KRenderingFigureProvider
    
    /** User-specified diagram synthesis options. */
    private var Options options
    
    
    
    /**
     * Annotates the given KGraph with the information necessary to render it as a Ptolemy model.
     * 
     * @param kGraph the KGraph created from a Ptolemy model.
     * @param options a container class holding synthesis option values
     */
    def void visualize(KNode kGraph, Options options) {
        this.options = options
        
        // Set the layout lagorithm for the graph and install a basic rendering to be able to install
        // the focus and context action
        kGraph.setLayoutAlgorithm()
        addRootRendering(kGraph)
        
        // Recurse into subnodes
        visualizeRecursively(kGraph)
    }
    
    /**
     * Annotates the children of the given node with the information necessary to render them and
     * calls itself recursively with each of the nodes.
     * 
     * @param node the node to visualize.
     * @param firstLevel {@code true} if the given node is the root of the graph. Used to auto-expand
     *                   compound nodes on the first level.
     */
    def private void visualizeRecursively(KNode node) {
        // Visualize child nodes
        for (child : node.children) {
            // Add child node rendering
            if (child.markedAsState) {
                // We have a state machine state (which may also be a compound state)
                child.addStateNodeRendering()
                visualizeRecursively(child)
            } else if (!child.children.empty) {
                // We have a compound node that is not a state
                child.addCompoundNodeRendering()
                visualizeRecursively(child)
            } else if (child.markedAsHypernode) {
                // We have a hypernode (a relation node, in Ptolemy speak)
                child.addRelationNodeRendering()
            } else if (child.markedAsDirector) {
                // We have a director node
                child.addDirectorNodeRendering()
            } else if (child.markedAsComment) {
                // We have a comment node
                child.addCommentNodeRendering()
            } else if (child.markedAsParameterNode) {
                // We have a parameter node that displays model parameters
                child.addParameterNodeRendering()
            } else if (child.markedAsDocumentationNode){
                //We have a documentation attribute node
                child.addDocumentationNodeRendering()    
            } else if (child.markedAsValueDisplayingActor) {
                // We have a value displaying actor whose rendering is a bit special
                child.addValueDisplayingNodeRendering()
            } else if (child.markedAsModalModelPort) {
                // We have a modal model port
                child.addModalModelPortRendering()
            } else {
                // We have a regular node
                child.addRegularNodeRendering()
            }
            
            // Add port rendering
            for (port : child.ports) {
                port.addPortRendering()
                port.addLabelRendering()
                port.addToolTip()
            }
            
            // Add edge rendering
            for (edge : child.outgoingEdges) {
                edge.addEdgeRendering()
                edge.addLabelRendering()
            }    
            
            // Add label rendering
            child.addLabelRendering()
            
            // Add tool tip
            child.addToolTip()
        }
    }
    
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////
    // Rendering of Nodes
    
    /**
     * Renders the given node as a compound node.
     * 
     * @param node the node to attach the rendering information to.
     */
    def private void addRootRendering(KNode node) {
        val rendering = node.createDefaultRendering(false);
        if (options.portLabels == LabelDisplayStyle.SELECTED) {
            rendering.addSingleClickAction(FocusAndContextAction.ID)
        }
        
        node.data += rendering;
    }
    
    /**
     * Renders the given node as a compound node.
     * 
     * @param node the node to attach the rendering information to.
     */
    def private void addCompoundNodeRendering(KNode node) {
        node.setProperty(KlighdProperties::EXPAND, !options.initiallyCollapsed)
        node.setProperty(CoreOptions::NODE_LABELS_PLACEMENT, EnumSet::of(
            NodeLabelPlacement::OUTSIDE, NodeLabelPlacement::H_LEFT, NodeLabelPlacement::V_TOP))
        ExpansionAwareLayoutOption::setProperty(node, CoreOptions::PORT_CONSTRAINTS,
            PortConstraints::FIXED_ORDER, PortConstraints::FREE)
        node.setProperty(CoreOptions::NODE_SIZE_CONSTRAINTS, SizeConstraint::fixed)
        
        node.setLayoutAlgorithm()
        
        // Add a rendering for the collapsed version of this node
        val collapsedRendering = createRegularNodeRendering(node);
        DiagramSyntheses.addRenderingWithStandardSelectionWrapper(node, collapsedRendering) => [
            it.setProperty(KlighdProperties::COLLAPSED_RENDERING, true)
            it.addDoubleClickAction(KlighdConstants::ACTION_COLLAPSE_EXPAND)
            if (options.portLabels == LabelDisplayStyle.SELECTED || options.comments == LabelDisplayStyle.SELECTED) {
                it.addSingleClickAction(FocusAndContextAction.ID)
            }
        ];
        
        //layout.setLayoutSize(collapsedRendering)
        
        // Create the rendering for the expanded version of this node
        val expandedRendering = createExpandedCompoundNodeRendering(node, options.compoundNodeAlpha);
        DiagramSyntheses.addRenderingWithStandardSelectionWrapper(node, expandedRendering) => [
            it.setProperty(KlighdProperties::EXPANDED_RENDERING, true)
            it.addDoubleClickAction(KlighdConstants::ACTION_COLLAPSE_EXPAND)
            if (options.portLabels == LabelDisplayStyle.SELECTED || options.comments == LabelDisplayStyle.SELECTED) {
                it.addSingleClickAction(FocusAndContextAction.ID)
            }
        ];
    }
    
    /**
     * Renders the given node as a state machine state.
     * 
     * @param node the node to attach the rendering information to.
     */
    def private void addStateNodeRendering(KNode node) {
        if (node.children.empty) {
            val rendering = createStateNodeRendering(node)
            node.data += rendering
        } else {
            node.setProperty(KlighdProperties::EXPAND, false)
            node.setProperty(CoreOptions::NODE_SIZE_CONSTRAINTS, SizeConstraint::fixed)
            
            node.setLayoutAlgorithm()
            
            // Add a rendering for the collapsed version of this node
            val collapsedRendering = createStateNodeRendering(node)
            collapsedRendering.setProperty(KlighdProperties::COLLAPSED_RENDERING, true)
            collapsedRendering.addAction(Trigger::DOUBLECLICK, KlighdConstants::ACTION_COLLAPSE_EXPAND)
            if (options.portLabels == LabelDisplayStyle.SELECTED) {
                collapsedRendering.addSingleClickAction(FocusAndContextAction.ID)
            }
            node.data += collapsedRendering
            
            // Create the rendering for the expanded version of this node
            val expandedRendering = createExpandedCompoundNodeRendering(node, options.compoundNodeAlpha)
            expandedRendering.setProperty(KlighdProperties::EXPANDED_RENDERING, true)
            expandedRendering.addAction(Trigger::DOUBLECLICK, KlighdConstants::ACTION_COLLAPSE_EXPAND)
            if (options.portLabels == LabelDisplayStyle.SELECTED) {
                expandedRendering.addSingleClickAction(FocusAndContextAction.ID)
            }
            node.data += expandedRendering
        }
    }
    
    /**
     * Renders the given node as a relation node. Also removes the relation's labels.
     * 
     * @param node the node to attach the rendering information to.
     */
    def private void addRelationNodeRendering(KNode node) {
        // Remove the relation's labels
        node.labels.clear()
        
        // Create the rendering
        val rendering = createRelationNodeRendering(node)
        if (options.portLabels == LabelDisplayStyle.SELECTED) {
            rendering.addSingleClickAction(FocusAndContextAction.ID)
        }
        node.data += rendering
        
        // Set size
        node.height = 10
        node.width = 10
    }
    
    /**
     * Renders the given node as a director.
     * 
     * @param node the node to attach the rendering information to.
     */
    def private void addDirectorNodeRendering(KNode node) {
        node.setProperty(CoreOptions::NODE_LABELS_PLACEMENT, EnumSet::of(
            NodeLabelPlacement::OUTSIDE, NodeLabelPlacement::H_LEFT, NodeLabelPlacement::V_TOP))
        node.setProperty(CoreOptions::PRIORITY, 1000)
        
        // Create the rendering
        val rendering = createDirectorNodeRendering(node)
        node.data += rendering
        
        // Set size
        node.setLayoutSize(rendering)
    }
    
    /**
     * Renders the given node as a comment node.
     * 
     * @param node the node to attach the rendering information to.
     */
    def private void addCommentNodeRendering(KNode node) {
        // Create the rendering for the node and its label (which it must have)
        val nodeRendering = createCommentNodeRendering(node)
        node.data += nodeRendering
        
        val label = node.labels.get(0);
        val labelRendering = createCommentLabelRendering(node, label);
        label.data += labelRendering;
        
        // The node must have its size calculated for its label
        node.setProperty(CoreOptions.NODE_LABELS_PLACEMENT, NodeLabelPlacement.insideCenter);
        node.setProperty(CoreOptions.NODE_SIZE_CONSTRAINTS, EnumSet.of(SizeConstraint.NODE_LABELS));
        
        // Support focus and context
        if (options.comments == LabelDisplayStyle.SELECTED) {
            nodeRendering.addSingleClickAction(FocusAndContextAction.ID)
            labelRendering.addSingleClickAction(FocusAndContextAction.ID)
        }
        
        // The rendering of all the comments edges is also special
        // (note: the current implementation of the comment attachment heuristic only runs after the
        // visualization data have been attached; thus, no edges connect comments and nodes at this
        // point. However, the code remains here in case the heuristic changes later)
        for (edge : node.incidentEdges) {
            val edgeRendering = createCommentEdgeRendering(edge)
            edge.data += edgeRendering
        }
    }
    
    /**
     * Renders the given node as a documentation node.
     * 
     * @param node the node to attach the rendering information to.
     */
    def private void addDocumentationNodeRendering(KNode node) {
        // Create the rendering
        val rendering = createDocumentationNodeRendering(node)
        node.data += rendering
    }
    
    /**
     * Renders the given node as a parameter node.
     * 
     * @param node the node to attach the rendering information to.
     */
    def private void addParameterNodeRendering(KNode node) {   
        node.setProperty(CoreOptions::PRIORITY, 800)
        
        // Create the rendering
        val rendering = createParameterNodeRendering(node)
        if (options.portLabels == LabelDisplayStyle.SELECTED) {
            rendering.addSingleClickAction(FocusAndContextAction.ID)
        }
        node.data += rendering
    }
    
    /**
     * Renders the given node displaying a specific value, for instance a Const actor.
     * 
     * @param node the node to attach the rendering information to.
     */
    def private void addValueDisplayingNodeRendering(KNode node) {
        node.setProperty(CoreOptions::NODE_LABELS_PLACEMENT, EnumSet::of(
            NodeLabelPlacement::OUTSIDE, NodeLabelPlacement::H_LEFT, NodeLabelPlacement::V_TOP))
        node.setProperty(CoreOptions::PORT_LABELS_PLACEMENT, EnumSet.of(PortLabelPlacement::OUTSIDE))
        node.setProperty(CoreOptions::PORT_CONSTRAINTS, PortConstraints::FIXED_ORDER)
        
        // Create the rendering
        val className = Strings.nullToEmpty(node.getAnnotationValue(ANNOTATION_PTOLEMY_CLASS))
        val value = node.getAnnotationValue(TransformationConstants.VALUE_DISPLAY_MAP.get(className))
        val rendering = createValueDisplayingNodeRendering(node, value ?: "")
        if (options.portLabels == LabelDisplayStyle.SELECTED) {
            rendering.addSingleClickAction(FocusAndContextAction.ID)
        }
        node.data += rendering
    }
    
    /**
     * Renders the given node as a modal model port.
     * 
     * @param node the node to attach the rendering information to.
     */
    def private void addModalModelPortRendering(KNode node) {
        // We currently disable node label placement because dot doesn't know how to do that (we use
        // dot for modal models)
        
//        node.setProperty(LayoutOptions::NODE_LABEL_PLACEMENT, EnumSet::of(
//            NodeLabelPlacement::OUTSIDE, NodeLabelPlacement::H_LEFT, NodeLabelPlacement::V_TOP))
        node.setProperty(CoreOptions::PORT_CONSTRAINTS, PortConstraints::FIXED_SIDE)
        
        val rendering = createModalModelPortRendering(node)
        if (options.portLabels == LabelDisplayStyle.SELECTED) {
            rendering.addSingleClickAction(FocusAndContextAction.ID)
        }
        node.data += rendering
        
        node.height = 20
        node.width = 20
    }
    
    /**
     * Renders the given node just like it would be rendered in Ptolemy, if possible.
     * 
     * @param node the node to attach the rendering information to.
     */
    def private void addRegularNodeRendering(KNode node) {
        node.setProperty(CoreOptions::NODE_LABELS_PLACEMENT, EnumSet::of(
            NodeLabelPlacement::OUTSIDE, NodeLabelPlacement::H_LEFT, NodeLabelPlacement::V_TOP))
        node.setProperty(CoreOptions::PORT_LABELS_PLACEMENT, EnumSet.of(PortLabelPlacement::OUTSIDE))
        node.setProperty(CoreOptions::PORT_CONSTRAINTS, PortConstraints::FIXED_ORDER)
        
        // Some kinds of nodes require special treatment
        val KRendering rendering = switch node.getAnnotationValue(ANNOTATION_PTOLEMY_CLASS) {
            case "ptolemy.actor.lib.Accumulator" : createAccumulatorNodeRendering(node)
            default : createRegularNodeRendering(node)
        }
        
        val selRendering = DiagramSyntheses.addRenderingWithStandardSelectionWrapper(node, rendering);
        
        // We need to enable focus and context if either port labels or comments are set to SELECTED (comments attached
        // to a node need to be focussed if that node is selected)
        if (options.portLabels == LabelDisplayStyle.SELECTED || options.comments == LabelDisplayStyle.SELECTED) {
            selRendering.addSingleClickAction(FocusAndContextAction.ID)
        }
        
        // Calculate layout size.
        node.setLayoutSize(rendering)
    }
    
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////
    // Rendering of Ports
    
    /**
     * Adds KRendering information to the given port.
     * 
     * @param port the port to add rendering information to.
     */
    def private void addPortRendering(KPort port) {
        // Find the port type
        val inputPort = port.markedAsInputPort
        val outputPort = port.markedAsOutputPort
        
        // Find the port side
        val ptolemySpecifiedPortSide = port.getAnnotationValue("_cardinal")
        var portSide = PortSide::UNDEFINED
        
        // If Ptolemy specifies a port side, use that
        try {
            portSide = PortSide::valueOf(ptolemySpecifiedPortSide)
        } catch (Exception e) {
            // Happens if there is no port side or the specification doesn't match our expectations
        }
        
        // If the port side is still undefined, infer it from the port type
        if (portSide == PortSide::UNDEFINED) {
            if (inputPort && outputPort) {
                portSide = PortSide::SOUTH
            } else if (inputPort) {
                portSide = PortSide::WEST
            } else {
                portSide = PortSide::EAST
            }
        }
        
        port.setProperty(CoreOptions::PORT_SIDE, portSide)
        
        // Set port properties depending on the port side
        val index = port.getProperty(CoreOptions::PORT_INDEX)
        switch portSide {
            case PortSide::NORTH: {
                port.setProperty(CoreOptions::PORT_BORDER_OFFSET, 0.0)
            }
            case PortSide::SOUTH: {
                port.setProperty(CoreOptions::PORT_BORDER_OFFSET, 0.0)
                port.setProperty(CoreOptions::PORT_INDEX, -index);
            }
            case PortSide::EAST: {
                port.setProperty(CoreOptions::PORT_BORDER_OFFSET, 0.0)
                if (!port.markedAsModalModelPort) {
                    port.setProperty(CoreOptions::PORT_ANCHOR, new KVector(7, 3.5))
                }
            }
            case PortSide::WEST: {
                port.setProperty(CoreOptions::PORT_BORDER_OFFSET, 0.0)
                if (!port.markedAsModalModelPort) {
                    port.setProperty(CoreOptions::PORT_ANCHOR, new KVector(0, 3.5))
                }
                port.setProperty(CoreOptions::PORT_INDEX, -index);
            }
            case PortSide::UNDEFINED: {
                // We don't know what to do
            }
        }
        
        // Add rendering if this is not a modal model port
        var KRendering rendering = null
        if (!port.markedAsModalModelPort) {
            rendering = createPortRendering(port)
            port.data += rendering
            
            // Add size information
            port.width = 8
            port.height = 8
        }
        
        // Check if the port has a name
        if (port.name.length > 0) {
            if (port.markedAsModalModelPort) {
                // This is a model port, put the name into the parent node's label
                port.node.name = port.name
            } else {
                rendering.setProperty(KlighdProperties::TOOLTIP, "Port: " + port.name)
            }
        }
        
        // Remove the port's label if necessary
        if (options.portLabels == LabelDisplayStyle.NONE) {
            port.labels.clear()
        }
    }
    
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////
    // Rendering of Edges
    
    /**
     * Adds KRendering information to the given edge.
     * 
     * @param edge the edge to add rendering information to.
     */
    def private void addEdgeRendering(KEdge edge) {
        if (edge.source.markedAsState || edge.target.markedAsState) {
            // If the edge has state transition annotations, we need to visualize those
            val labelText = new StringBuffer()
            
            val annotation = edge.getAnnotationValue(ANNOTATION_ANNOTATION)
            if (!annotation.nullOrEmpty) {
                labelText.append("\n" + annotation)
            }
            
            val guardExpression = edge.getAnnotationValue(ANNOTATION_GUARD_EXPRESSION)
            if (!guardExpression.nullOrEmpty) {
                labelText.append("\nGuard: " + guardExpression)
            }
            
            val outputActions = edge.getAnnotationValue(ANNOTATION_OUTPUT_ACTIONS)
            if (!outputActions.nullOrEmpty) {
                labelText.append("\nOutput: " + outputActions)
            }
            
            val setActions = edge.getAnnotationValue(ANNOTATION_SET_ACTIONS)
            if (!setActions.nullOrEmpty) {
                labelText.append("\nSet: " + setActions)
            }
            
            // Actually set the label text if we found anything worthwhile and also set the edge
            // label placement accordingly
            if (labelText.length > 0) {
                edge.name = labelText.substring(1)
                
                val label = edge.labels.get(0)
                label.setProperty(CoreOptions::EDGE_LABELS_PLACEMENT, EdgeLabelPlacement::CENTER)
            }
            
            // Now finally add an edge rendering, which in turn depends on additional stuff...
            val rendering = createTransitionRendering(edge)
            edge.data += rendering
        } else {
            // We have a regular edge
            edge.data += createDataFlowRendering(edge);
        }
    }
    
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////
    // Rendering of Labels
    
    /**
     * Attaches rendering information to all labels of the given element.
     * 
     * @param elemtent the element.
     */
    def private void addLabelRendering(KLabeledGraphElement element) {
        for (label : element.labels) {
            // Add empty selectable text rendering
            val ktext = DiagramSyntheses.addRenderingWithStandardSelectionWrapper(label, null).addText(null)
            ktext.cursorSelectable = true
            
            // If we have a modal model port, we need to determine a fixed placement for the label at
            // this point
            if (element.markedAsModalModelPort) {
                val bounds = PlacementUtil::estimateSize(label)
                
                label.xpos = 0
                label.ypos = -(bounds.height + 3.0f)
            }
            
            // Make the text of edge and port labels a bit smaller
            if (element instanceof KEdge) {
                ktext.fontSize = KlighdConstants::DEFAULT_FONT_SIZE - 2
            } else if (element instanceof KPort) {
                ktext.fontSize = KlighdConstants::DEFAULT_FONT_SIZE - 3
            }
        }
    }
    
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////
    // Tool Tips
    
    /**
     * Generates a tool tip for the given element based on its properties if it has rendering
     * information. (modal model ports don't have any)
     * 
     * @param element the element to generate the tooltip for.
     */
    def private void addToolTip(KGraphElement element) {
        val krendering = element.KRendering
        if (krendering === null) {
            return
        }
        
        val toolTip = krendering.getProperty(KlighdProperties::TOOLTIP)
        val toolTipText = new StringBuffer()
        
        // If we already have a tool tip text, add that to our newly assembled text
        if (!toolTip.nullOrEmpty) {
            toolTipText.append("\n" + toolTip)
        }
        
        // Look for properties that don't start with an underscore (these are the ones we want the
        // user to see)
        for (property : element.annotations) {
            /* We have a few conditions that would cause an annotation to not be shown in a comment:
             *  1. It starts with an underscore "_"
             *  2. The element is a comment node and the annotation holds its text.
             */
            val includeAnnotation =
                !property.name.startsWith("_")
                && !((element instanceof KNode)
                    && (element as KNode).markedAsComment
                    && property.name.equals(ANNOTATION_COMMENT_TEXT))
            
            if (includeAnnotation) {
                toolTipText.append("\n").append(property.name)
                
                if (!property.value.nullOrEmpty) {
                    toolTipText.append(": ").append(property.value)
                }
            }
        }
        
        // If we have found something, display them as tooltip
        if (toolTipText.length > 0) {
            krendering.setProperty(KlighdProperties::TOOLTIP, toolTipText.substring(1))
        }
    }
    
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////
    // Utility Methods
    
    /**
     * Sets the layout size depending on the information in the given rendering information.
     * 
     * @param layout the layout object to set size information on.
     * @param rendering the rendering to infer the size information from. May be {@code null}, in which
     *                  case a default size is assumed.
     */
    def private void setLayoutSize(KShapeLayout layout, KRendering rendering) {
        // TODO Provide proper size information for every actor
        var actualRendering = rendering
        while (actualRendering instanceof KRenderingRef) {
            actualRendering = (actualRendering as KRenderingRef).rendering
        }
                
        if (actualRendering === null) {
            // If we have no rendering in the first place, fix the size
            layout.height = 50
            layout.width = 50
        } else if (actualRendering.placementData !== null
            && actualRendering.placementData instanceof KAreaPlacementData) {
            
            // We have concrete placement data to infer the size from
            val placementData = actualRendering.placementData as KAreaPlacementData
            
            layout.height = placementData.bottomRight.y.absolute
            layout.width = placementData.bottomRight.x.absolute
        } else {
            // Use a default minimum size
            layout.setProperty(KlighdProperties::MINIMAL_NODE_SIZE, new KVector(60, 40))
            layout.setProperty(CoreOptions::NODE_SIZE_CONSTRAINTS,
                EnumSet::of(SizeConstraint::MINIMUM_SIZE)
            )
        }
    }
    
    /**
     * Sets the layout algorithm of the given node depending on which kind of diagram the node hosts.
     * 
     * @param node the node to set the layout algorithm information on.
     */
    def private void setLayoutAlgorithm(KNode node) {
        // Check if this is a state machine
        if (node.markedAsStateMachineContainer) {
            node.setProperty(CoreOptions::ALGORITHM, LayeredOptions.ALGORITHM_ID)
            node.setProperty(CoreOptions::EDGE_ROUTING, EdgeRouting::SPLINES)
        } else {
            node.setProperty(CoreOptions::ALGORITHM, LayeredOptions.ALGORITHM_ID)
            node.setProperty(CoreOptions::EDGE_ROUTING, EdgeRouting::ORTHOGONAL)
            
            // explicitly set a node direction as we do not want the diagram nodeed 
            // top-down due to direction inference of klay layered (almost always looks ugly)
            node.setProperty(CoreOptions.DIRECTION, Direction.RIGHT)
        }
    }
}
