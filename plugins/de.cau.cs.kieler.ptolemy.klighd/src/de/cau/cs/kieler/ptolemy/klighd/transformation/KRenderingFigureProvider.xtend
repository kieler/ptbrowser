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
package de.cau.cs.kieler.ptolemy.klighd.transformation

import com.google.inject.Inject
import de.cau.cs.kieler.klighd.KlighdConstants
import de.cau.cs.kieler.klighd.kgraph.KEdge
import de.cau.cs.kieler.klighd.kgraph.KLabel
import de.cau.cs.kieler.klighd.kgraph.KNode
import de.cau.cs.kieler.klighd.kgraph.KPort
import de.cau.cs.kieler.klighd.krendering.HorizontalAlignment
import de.cau.cs.kieler.klighd.krendering.KContainerRendering
import de.cau.cs.kieler.klighd.krendering.KDecoratorPlacementData
import de.cau.cs.kieler.klighd.krendering.KPolyline
import de.cau.cs.kieler.klighd.krendering.KRendering
import de.cau.cs.kieler.klighd.krendering.KRenderingFactory
import de.cau.cs.kieler.klighd.krendering.KRenderingLibrary
import de.cau.cs.kieler.klighd.krendering.KRenderingRef
import de.cau.cs.kieler.klighd.krendering.LineStyle
import de.cau.cs.kieler.klighd.krendering.VerticalAlignment
import de.cau.cs.kieler.klighd.krendering.extensions.KColorExtensions
import de.cau.cs.kieler.klighd.krendering.extensions.KContainerRenderingExtensions
import de.cau.cs.kieler.klighd.krendering.extensions.KPolylineExtensions
import de.cau.cs.kieler.klighd.krendering.extensions.KRenderingExtensions
import de.cau.cs.kieler.ptolemy.klighd.transformation.extensions.AnnotationExtensions
import de.cau.cs.kieler.ptolemy.klighd.transformation.extensions.LabelExtensions
import de.cau.cs.kieler.ptolemy.klighd.transformation.extensions.MarkerExtensions
import de.cau.cs.kieler.ptolemy.klighd.transformation.extensions.MiscellaneousExtensions
import de.cau.cs.kieler.ptolemy.klighd.transformation.util.GraphicsUtils

import static de.cau.cs.kieler.ptolemy.klighd.PtolemyProperties.*
import static de.cau.cs.kieler.ptolemy.klighd.transformation.util.TransformationConstants.*

/**
 * Creates concrete KRendering information for Ptolemy diagram elements.
 * 
 * @author ckru
 * @author cds
 * @author uru
 */
class KRenderingFigureProvider {
    
    /** Accessing annotations. */
    @Inject extension AnnotationExtensions
    /** Handling labels. */
    @Inject extension LabelExtensions
    /** Marking nodes. */
    @Inject extension MarkerExtensions
    /** Extensions used during the transformation. To make things easier. And stuff. */
    @Inject extension MiscellaneousExtensions
    /** Create KRenderings from Ptolemy figures. */
    @Inject extension PtolemyFigureInterface
    /** Color stuff. */
    @Inject extension KColorExtensions
    /** Rendering stuff. */
    @Inject extension KRenderingExtensions
    /** Rendering stuff. */
    @Inject extension KContainerRenderingExtensions
    /** Rendering stuff. */
    @Inject extension KPolylineExtensions
    
    /** Rendering factory used to instantiate KRendering instances. */
    val renderingFactory = KRenderingFactory::eINSTANCE
    
   
    
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////
    // Node Renderings
    
    /**
     * Returns the rendering library associated with the given node. The associated rendering library is
     * the library of the root ancestor of the node. If no library exists yet, one is created and
     * attached to the root ancestor.
     * 
     * @param node the node whose's rendering library to return.
     * @return the rendering library associated with the given node.
     */
    def private KRenderingLibrary getLibrary(KNode node) {
        var parent = node
        while (parent.parent !== null) {
            parent = parent.getParent()
        }
        
        var library = parent.getData(typeof(KRenderingLibrary))
        if (library === null) {
            library = renderingFactory.createKRenderingLibrary()
            parent.data.add(library)
        }
        
        return library
    }
    
    /**
     * Returns a reference to rendering with the given ID in the given library.
     * 
     * @param id identifier of the rendering to look up.
     * @param library the rendering library to search for the rendering.
     * @return new rendering reference to the rendering, or {@code null} if no rendering with the given
     *         identifier exists in the library.
     */
    def private KRenderingRef getFromLibrary(String id, KRenderingLibrary library) {
        val rendering = library.renderings.findFirst[r | r.id == id] as KRendering
        
        if (rendering !== null) {
            val ref = renderingFactory.createKRenderingRef()
            ref.rendering = rendering
            return ref
        } else {
            return null
        }
    }
    
    /**
     * Adds the given rendering to the given rendering library with the given id.
     * 
     * @param rendering the rendering to add to the library.
     * @param id the id that will identify the rendering in the library.
     * @param library the library to add the rendering to.
     */
    def private KRenderingRef addToLibrary(KRendering rendering, String id, KRenderingLibrary library) {
        rendering.id = id
        library.renderings.add(rendering)
        
        val ref = renderingFactory.createKRenderingRef()
        ref.rendering = rendering
        return ref
    }
    
    /**
     * Renders the given node in a default way, that is, as a simple rectangle.
     *
     * @param node the node to create the default rendering for.
     * @param fixSize {@code true} if the node's size should be fixed to a default value of (60, 40);
     *                {@code false} if the node's size will be determined dynamically later on. 
     * @return the created rendering.
     */
    def KRendering createDefaultRendering(KNode node, boolean fixSize) {
        val rendering = renderingFactory.createKRectangle() => [rect |
            rect.setBackgroundColor(255, 255, 255)
            
            if (fixSize) {
                rect.setAreaPlacementData(
                    createKPosition(LEFT, 0, 0, TOP, 0, 0),
                    createKPosition(LEFT, 60, 0, TOP, 40, 0))
            }
        ]
        
        return rendering
    }
    
    /**
     * Creates a rendering for an expanded compound node.
     * 
     * @param node the node to create the rendering information for.
     * @param alpha the alpha value of the compound node background.
     * @return the rendering.
     */
    def KRendering createExpandedCompoundNodeRendering(KNode node, int alpha) {
        val bgColor = if (node.markedAsState) {
            renderingFactory.createKColor() => [col |
                col.red = 11
                col.green = 188
                col.blue = 11
            ]
        } else {
            renderingFactory.createKColor() => [col |
                col.red = 16
                col.green = 78
                col.blue = 139
            ]
        }
        
        val rendering = renderingFactory.createKRoundedRectangle() => [rect |
            rect.cornerHeight = 15
            rect.cornerWidth = 15
            rect.setLineWidth(if (node.markedAsState) 1 else 0)
            rect.styles += renderingFactory.createKBackground() => [bg |
                bg.alpha = alpha
                bg.color = bgColor
            ]
        ]
        
        return rendering
    }
    
    /**
     * Creates a rendering for a relation node.
     * 
     * @param node the node to create the rendering information for.
     * @return the rendering.
     */
    def KRendering createRelationNodeRendering(KNode node) {
        val library = getLibrary(node)
        val rendering = getFromLibrary("ren_relation", library)
        if (rendering !== null) {
            return rendering
        }
        
        return addToLibrary(renderingFactory.createKPolygon() => [poly |
            poly.points += createKPosition(4, 0)
            poly.points += createKPosition(8, 4)
            poly.points += createKPosition(4, 8)
            poly.points += createKPosition(0, 4)
            poly.points += createKPosition(4, 0)
            poly.setBackgroundColor(0, 0, 0)
        ], "ren_relation", library)
    }
    
    /**
     * Creates a rendering for a director node.
     * 
     * @param node the node to create the rendering information for.
     * @return the rendering.
     */
    def KRendering createDirectorNodeRendering(KNode node) {
        val library = getLibrary(node)
        val rendering = getFromLibrary("ren_director", library)
        if (rendering !== null) {
            return rendering
        }
        
        return addToLibrary(renderingFactory.createKRectangle() => [rec |
            rec.background = "green".color
            rec.foreground = "black".color
            rec.setAreaPlacementData(
                createKPosition(LEFT, 0, 0, TOP, 0, 0),
                createKPosition(LEFT, 100, 0, TOP, 30, 0)
            )
        ], "ren_director", library)
    }
    
    /**
     * Creates a rendering for a comment node.
     * 
     * @param node the node to create the rendering information for.
     * @return the rendering.
     */
    def KRendering createCommentNodeRendering(KNode node) {
        val library = getLibrary(node)
        val rendering = getFromLibrary("ren_comment", library)
        if (rendering !== null) {
            return rendering
        }
        
        return addToLibrary(renderingFactory.createKRectangle() => [rec |
            rec.background = renderingFactory.createKColor() => [col |
                col.red = 255
                col.green = 255
                col.blue = 204
            ]
            rec.setLineWidth(0)
        ], "ren_comment", library)
    }
    
    /**
     * Creates a rendering for a comment node's text label.
     * 
     * @param node the node that represents the comment.
     * @param label the node's label that contains the comment's text.
     * @return the rendering.
     */
    def KRendering createCommentLabelRendering(KNode node, KLabel label) {
        if(node.markedAsTitleNode){
            return renderingFactory.createKText() => [text |
                text.fontSize = 18
            ]   
        } else {
           return renderingFactory.createKText() => [text |
                text.fontSize = node.getProperty(COMMENT_FONT_SIZE) - 2
            ]
        }
    }
    
    /**
     * Creates a rendering for a documentation attribute node.
     * 
     * @param node the node to create the rendering information for.
     * @return the rendering.
     */
    def KRendering createDocumentationNodeRendering(KNode node) {
        //look whether the rendering can be found in the library
        val library = getLibrary(node)
        val rendering = getFromLibrary("ren_documentation", library)
        if (rendering !== null) {
            return rendering
        }
        
        //Otherwise, create a rendering
        val rectangle = renderingFactory.createKRectangle() => [rec |
            rec.background = "yellow".color
            rec.foreground = "black".color
        ]
        
        //Add the node's text
        rectangle.children += renderingFactory.createKText() => [text |
            text.fontSize = 8
            text.text = "Documentation"
            text.setSurroundingSpace(5, 0)
        ]
        
        //Add the new rendering to the library
        addToLibrary(rectangle, "ren_documentation", library)
        
        return rectangle
    }
    
    
    /**
     * Creates a rendering for a parameter node. Parameter nodes display model parameters in a grid-like
     * fashion.
     * 
     * @param node the node to create the rendering information for.
     * @return the rendering.
     */
    def KRendering createParameterNodeRendering(KNode node) {
        // Create the surrounding container rendering with a three-column grid placement
        val rectangle = renderingFactory.createKRectangle() => [rec |
            rec.foregroundInvisible = true
            rec.childPlacement = renderingFactory.createKGridPlacement() => [grid |
                grid.numColumns = 3
            ]
        ]
        
        // Find the parameters that should be displayed
        val parameters = node.getProperty(PT_PARAMETERS)
        
        // Visualize each parameter
        for (parameter : parameters) {
                val circle = renderingFactory.createKEllipse() => [ell |
                ell.background = GraphicsUtils::lookupColor("blue")
                ell.setGridPlacementData(
                    15,
                    15,
                    createKPosition(LEFT, -4, 0.5f, TOP, -4, 0.5f),
                    createKPosition(RIGHT, -4, 0.5f, BOTTOM, -4, 0.5f))
                ell.lineWidth = 1
            ]
            rectangle.children += circle
            
            val nameText = renderingFactory.createKText()  => [name |
                name.text = parameter.first + ":"
                name.horizontalAlignment = H_LEFT
                name.setFontSize(KlighdConstants::DEFAULT_FONT_SIZE - 2)
                name.setGridPlacementData(
                    0,
                    0,
                    createKPosition(LEFT, 0, 0, TOP, 3, 0),
                    createKPosition(RIGHT, 5, 0, BOTTOM, 3, 0))
            ]
            rectangle.children += nameText
            
            val valueText = renderingFactory.createKText()  => [value |
                // We shorten the text to 150 characters. This could definitely be done in a more
                // intelligent way (with label management techniques, perhaps), but this is good enough
                // for the moment
                value.text = if (parameter.second.length > 150) {
                        parameter.second.substring(0, 150) + "..."
                    } else {
                        parameter.second
                    }
                value.horizontalAlignment = H_LEFT
                value.setFontSize(KlighdConstants::DEFAULT_FONT_SIZE - 2)
                value.setGridPlacementData(
                    0,
                    0,
                    createKPosition(LEFT, 5, 0, TOP, 3, 0),
                    createKPosition(RIGHT, 5, 0, BOTTOM, 3, 0))
            ]
            rectangle.children += valueText
            
        }
        
        return rectangle
    }
    
    /**
     * Creates a rendering for a state node.
     * 
     * @param node the node to create the rendering information for.
     * @return the rendering.
     */
    def KRendering createStateNodeRendering(KNode node) {
        // TODO this rendering could be put into the library if its text is kept generic
        val isFinal = node.getAnnotationBooleanValue("isFinalState")
        val isInitial = node.getAnnotationBooleanValue("isInitialState")
        val lineWidth = if (isInitial) 3 else 1
        val initialFinalInset = if (isInitial) 4 else 3
        
        // The background color depends on whether the state has a refinement
        val bgColor = if (node.markedAsHavingRefinement) {
            renderingFactory.createKColor() => [col |
                col.red = 204
                col.green = 255
                col.blue = 204
            ]
        } else {
            GraphicsUtils::lookupColor("white")
        }
        
        // Reset the regular label and replace it with a KText element; since we're using GraphViz dot
        // to layout state machines, the label wouldn't be placed properly anyway
        val label = renderingFactory.createKText() => [text |
            text.text = node.name
            text.setAreaPlacementData(
                createKPosition(LEFT, 14, 0, TOP, 8, 0),
                createKPosition(RIGHT, 14, 0, BOTTOM, 8, 0)
            )
        ]
        node.name = ""
        
        // Create the outer circle (which may remain the only one)
        val outerCircle = renderingFactory.createKRoundedRectangle() => [rec |
            rec.cornerHeight = 30
            rec.cornerWidth = 15
            rec.setAreaPlacementData(
                createKPosition(LEFT, 0, 0, TOP, 0, 0),
                createKPosition(RIGHT, 0, 0, BOTTOM, 0, 0)
            )
            rec.lineWidth = lineWidth
            rec.background = bgColor
        ]
        
        // If this is a final state, we need to add an inner circle as well
        if (isFinal) {
            val innerCircle = renderingFactory.createKRoundedRectangle() => [rec |
                rec.cornerHeight = 22
                rec.cornerWidth = 12
                rec.setAreaPlacementData(
                    createKPosition(LEFT, initialFinalInset, 0, TOP, initialFinalInset, 0),
                    createKPosition(RIGHT, initialFinalInset, 0, BOTTOM, initialFinalInset, 0)
                )
                rec.lineWidth = lineWidth
            ]
            innerCircle.children += label
            outerCircle.children += innerCircle
        } else {
            outerCircle.children += label
        }
        
        return outerCircle
    }
    
    /**
     * Creates a rendering for a node that displays a value.
     * 
     * @param node the node to create the rendering information for.
     * @param value the value the node should display.
     * @return the rendering.
     */
    def KRendering createValueDisplayingNodeRendering(KNode node, String value) {
        // TODO this rendering could be put into the library if its text is kept generic
        val nodeRendering = createDefaultRendering(node, false) as KContainerRendering
        
        // Add a text field to the default rendering
        nodeRendering.children += renderingFactory.createKText() => [text |
            text.text = value
            text.setSurroundingSpace(5, 0)
            text.setForeground(GraphicsUtils::lookupColor("darkgrey"))
        ]
        
        return nodeRendering
    }
    
    /**
     * Creates a rendering for a node that represents a modal model port.
     * 
     * @param node the node to create the rendering information for.
     * @return the rendering.
     */
    def KRendering createModalModelPortRendering(KNode node) {
        val input = node.markedAsInputPort
        val output = node.markedAsOutputPort
        val multiport = node.hasAnnotation("multiport")
        val id = "ren_" + (if (multiport) "multi" else "") + (if (input) "in" else "")
                + (if (output) "out" else "") + "mmport"
        
        val library = getLibrary(node)
        val rendering = getFromLibrary(id, library)
        if (rendering !== null) {
            return rendering
        }
        
        val polygon = renderingFactory.createKPolygon()
        
        if (multiport) {
            polygon.setBackgroundColor(255, 255, 255)
            
            if (input && !output) {
                polygon.points += createKPosition(0, 5)
                polygon.points += createKPosition(5, 5)
                polygon.points += createKPosition(5, 0)
                polygon.points += createKPosition(10, 5)
                polygon.points += createKPosition(10, 0)
                polygon.points += createKPosition(20, 10)
                polygon.points += createKPosition(10, 20)
                polygon.points += createKPosition(10, 15)
                polygon.points += createKPosition(5, 20)
                polygon.points += createKPosition(5, 15)
                polygon.points += createKPosition(0, 15)
                polygon.points += createKPosition(0, 5)
            } else if (!input && output) {
                polygon.points += createKPosition(0, 0)
                polygon.points += createKPosition(5, 5)
                polygon.points += createKPosition(5, 0)
                polygon.points += createKPosition(10, 5)
                polygon.points += createKPosition(20, 5)
                polygon.points += createKPosition(20, 15)
                polygon.points += createKPosition(10, 15)
                polygon.points += createKPosition(5, 20)
                polygon.points += createKPosition(5, 15)
                polygon.points += createKPosition(0, 20)
                polygon.points += createKPosition(0, 0)
            } else if (input && output) {
                polygon.points += createKPosition(0, 5)
                polygon.points += createKPosition(5, 5)
                polygon.points += createKPosition(5, 0)
                polygon.points += createKPosition(10, 5)
                polygon.points += createKPosition(10, 0)
                polygon.points += createKPosition(15, 5)
                polygon.points += createKPosition(20, 5)
                polygon.points += createKPosition(20, 15)
                polygon.points += createKPosition(15, 15)
                polygon.points += createKPosition(10, 20)
                polygon.points += createKPosition(10, 15)
                polygon.points += createKPosition(5, 20)
                polygon.points += createKPosition(5, 15)
                polygon.points += createKPosition(0, 15)
                polygon.points += createKPosition(0, 5)
            } else {
                polygon.points += createKPosition(0, 5)
                polygon.points += createKPosition(20, 5)
                polygon.points += createKPosition(20, 15)
                polygon.points += createKPosition(0, 15)
                polygon.points += createKPosition(0, 5)
            }
        } else {
            polygon.setBackgroundColor(0, 0, 0)
            
            if (input && !output) {
                polygon.points += createKPosition(10, 0)
                polygon.points += createKPosition(20, 10)
                polygon.points += createKPosition(10, 20)
                polygon.points += createKPosition(10, 15)
                polygon.points += createKPosition(0, 15)
                polygon.points += createKPosition(0, 5)
                polygon.points += createKPosition(10, 5)
                polygon.points += createKPosition(10, 0)
            } else if (!input && output) {
                polygon.points += createKPosition(0, 0)
                polygon.points += createKPosition(5, 5)
                polygon.points += createKPosition(20, 5)
                polygon.points += createKPosition(20, 15)
                polygon.points += createKPosition(5, 15)
                polygon.points += createKPosition(0, 20)
                polygon.points += createKPosition(0, 0)
            } else if (input && output) {
                polygon.points += createKPosition(0, 5)
                polygon.points += createKPosition(7, 5)
                polygon.points += createKPosition(7, 0)
                polygon.points += createKPosition(12, 5)
                polygon.points += createKPosition(20, 5)
                polygon.points += createKPosition(20, 15)
                polygon.points += createKPosition(12, 15)
                polygon.points += createKPosition(7, 20)
                polygon.points += createKPosition(7, 15)
                polygon.points += createKPosition(0, 15)
                polygon.points += createKPosition(0, 5)
            } else {
                polygon.points += createKPosition(0, 5)
                polygon.points += createKPosition(20, 5)
                polygon.points += createKPosition(20, 15)
                polygon.points += createKPosition(0, 15)
                polygon.points += createKPosition(0, 5)
            }
        }
        
        return addToLibrary(polygon, id, library)
    }
    
    /**
     * Creates a rendering for a regular node.
     * 
     * @param node the node to create the rendering information for.
     * @return the rendering.
     */
    def KRendering createRegularNodeRendering(KNode node) {
        if (node.getAnnotationValue(ANNOTATION_PTOLEMY_CLASS) !== null) {
            val id = "ren_" + node.getAnnotationValue(ANNOTATION_PTOLEMY_CLASS).replace('.', '')
            val library = getLibrary(node)
            val rendering = getFromLibrary(id, library)
            if (rendering !== null) {
                return rendering
            }
        
            val ptRendering = createPtolemyFigureRendering(
                node.getAnnotationValue(ANNOTATION_PTOLEMY_CLASS))
            if (ptRendering !== null) {
                return addToLibrary(ptRendering, id, library)
            }
        }
        
        return createDefaultRendering(node, true)
    }
    
    /**
     * Creates a rendering for an accumulator node. This needs to be a separate case because the SVG
     * description for accumulator nodes in Ptolemy is broken.
     * 
     * @param node the node to create the rendering information for.
     * @return the rendering.
     */
    def KRendering createAccumulatorNodeRendering(KNode node) {
        val library = getLibrary(node)
        val rendering = getFromLibrary("ren_accumulator", library)
        if (rendering !== null) {
            return rendering
        }
        
        val accumulatorSvg = "<svg height=\"41\" width=\"41\" >"
                + "<rect height=\"40\" style=\"fill:white;stroke:black;stroke-width:1\" "
                + "width=\"40\" x=\"0.0\" y=\"0.0\" />"
                + "<path d=\"m 29.126953,6.2304687 0,3.0410157 -13.833984,0 8.789062,9.3515626 "
                + "-8.789062,10.335937 14.554687,0 0,3.041016 -18.246093,0 "
                + "0,-3.550781 8.419921,-9.826172 -8.419921,-8.9648439 0,-3.4277344 z\" />"
                + "</svg>"
        return addToLibrary(GraphicsUtils::createFigureFromSvg(accumulatorSvg),
                "ren_accumulator", library)
    }
    
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////
    // Edge Renderings
    
    /**
     * Creates a rendering for an edge that represents a transition in a state machine.
     */
    def KRendering createTransitionRendering(KEdge edge) {
        return renderingFactory.createKSpline() => [spline |
            spline.lineWidth = 1.6f
            
            // Special rendering options for transition types
            if (edge.getAnnotationBooleanValue(ANNOTATION_NONDETERMINISTIC_TRANSITION)) {
                spline.foreground = GraphicsUtils::lookupColor("red")
            }
            
            if (edge.getAnnotationBooleanValue(ANNOTATION_DEFAULT_TRANSITION)) {
                spline.lineStyle = LineStyle::DASH
            }

            spline.addHeadArrowDecorator() => [
                // in case the 'reset' flag of the transition is 'false' ...
                if (!edge.getAnnotationBooleanValue(ANNOTATION_RESET_TRANSITION)) {

                    // ... move the arrow decorator a bit towards the edge source,
                    (it.placementData as KDecoratorPlacementData).absolute = -12

                    // and add a history decorator
                    spline.addHistoryDecorator()
                }
            ]
        ]
    }
    
    private def KRendering addHistoryDecorator(KPolyline line) {
        return line.addEllipse() => [
            it.lineWidth = 0.5f;
            it.background = "gray".color
            it.setDecoratorPlacementData(12, 12, -3, 1, false);
            it.addPolyline(1) => [
                it.points += createKPosition(LEFT, 3.5f, 0, TOP, 2.5f, 0);
                it.points += createKPosition(LEFT, 3.5f, 0, BOTTOM, 2.5f, 0);
                it.points += createKPosition(LEFT, 3.5f, 0, TOP, 0, 0.5f);
                it.points += createKPosition(RIGHT, 3.5f, 0, TOP, 0, 0.5f);
                it.points += createKPosition(RIGHT, 3.5f, 0, BOTTOM, 2.5f, 0);
                it.points += createKPosition(RIGHT, 3.5f, 0, TOP, 2.5f, 0);
            ]
        ]
    }
    
    /**
     * Creates a rendering for an edge that represents a data flow buffer.
     */
    def KRendering createDataFlowRendering(KEdge edge) {
        val library = getLibrary(edge.source)
        var junction = getFromLibrary("ren_junction", library)
        if (junction === null) {
            junction = addToLibrary(renderingFactory.createKPolygon() => [poly |
                poly.points += createKPosition(4, 0)
                poly.points += createKPosition(8, 4)
                poly.points += createKPosition(4, 8)
                poly.points += createKPosition(0, 4)
                poly.points += createKPosition(4, 0)
                poly.setBackgroundColor(0, 0, 0)
                poly.placementData = renderingFactory.createKPointPlacementData() => [ ppd |
                    ppd.horizontalAlignment = HorizontalAlignment.CENTER
                    ppd.verticalAlignment = VerticalAlignment.CENTER
                    ppd.minWidth = 8
                    ppd.minHeight = 8
                ]
            ], "ren_junction", library)
        }
        
        val rendering = renderingFactory.createKRoundedBendsPolyline() => [ polyLine |
            polyLine.bendRadius = 5f
            polyLine.lineWidth = 2f
        ]
        rendering.junctionPointRendering = junction
        
        return rendering
    }
    
    /**
     * Creates a rendering for an edge that attaches a comment node to a commented node.
     * 
     * @param edge the edge to create the rendering information for.
     * @return the rendering.
     */
    def KRendering createCommentEdgeRendering(KEdge edge) {
        val polyline = renderingFactory.createKPolyline() => [line |
            line.lineStyle = LineStyle::DASH
            line.lineWidth = 1
            line.foreground = GraphicsUtils::lookupColor("grey")
        ]
        
        return polyline
    }
    
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////
    // Port Renderings
    
    /** Width / height of a port. */
    private val PORT_SIZE = 7f
    
    /** Half the width / height of a port. */
    private val PORT_SIZE_HALF = 3.5f
    
    /** The id of the modifier that rotates the port renderings. */
    private val PORT_STYLE_MODIFIER_ID = "de.cau.cs.kieler.ptolemy.klighd.ptolemyPortStyleModifier"
    
    /**
     * Creates a rendering for a port.
     * 
     * @param port the port to create the rendering information for.
     * @return the rendering.
     */
    def KRendering createPortRendering(KPort port) {
        // Determine the port color
        val portFillColor = if (port.hasAnnotation(IS_PARAMETER_PORT)) {
            // Parameter ports are gray
            GraphicsUtils::lookupColor("gray")
        } else if (port.hasAnnotation(IS_IO_PORT) && port.hasAnnotation(IS_MULTIPORT)) {
            // IO Multiports are white
            GraphicsUtils::lookupColor("white")
        } else {
            // All other ports are black
            GraphicsUtils::lookupColor("black")
        }
        
        // Create the triangle (depending on the port size)
        val polygon = port.addPolygon()
        polygon.points += createKPosition(
                   LEFT, 0, 0, TOP, PORT_SIZE, 0)
               polygon.points += createKPosition(
                   LEFT, 0, 0, TOP, 0, 0)
               polygon.points += createKPosition(
                   LEFT, PORT_SIZE, 0, TOP, PORT_SIZE_HALF, 0)
               polygon.points += createKPosition(
                   LEFT, 0, 0, TOP, PORT_SIZE, 0)
        
        // We create only one representative polygon here: |>
        //  and rotate it according to its orientation after layout
        //  using a dedicated klighd style modifier.  
        polygon.rotation = 0f
        polygon.rotation.rotationAnchor = createKPosition(PORT_SIZE_HALF, PORT_SIZE_HALF)
        polygon.rotation.modifierId = PORT_STYLE_MODIFIER_ID
        
        // Set color properties
        polygon.setBackground(portFillColor)
        polygon.setForeground(GraphicsUtils::lookupColor("black"))
        
        return polygon
    }
    
}
