/*
 * KIELER - Kiel Integrated Environment for Layout Eclipse RichClient
 *
 * http://rtsys.informatik.uni-kiel.de/kieler
 * 
 * Copyright 2013 by
 * + Kiel University
 *   + Department of Computer Science
 *     + Real-Time and Embedded Systems Group
 * 
 * This code is provided under the terms of the Eclipse Public License (EPL).
 * See the file epl-v10.html for the license text.
 */
package de.cau.cs.kieler.ptolemy.klighd

import com.google.common.collect.ImmutableList
import com.google.inject.Inject
import de.cau.cs.kieler.klighd.SynthesisOption
import de.cau.cs.kieler.klighd.kgraph.KNode
import de.cau.cs.kieler.klighd.labels.management.AbstractKlighdLabelManager
import de.cau.cs.kieler.klighd.labels.management.HidingLabelManager
import de.cau.cs.kieler.klighd.labels.management.ListLabelManager
import de.cau.cs.kieler.klighd.labels.management.TruncatingLabelManager
import de.cau.cs.kieler.klighd.labels.management.TypeConditionLabelManager
import de.cau.cs.kieler.klighd.syntheses.AbstractDiagramSynthesis
import de.cau.cs.kieler.klighd.syntheses.DiagramSyntheses
import de.cau.cs.kieler.ptolemy.klighd.transformation.Ptolemy2KGraphOptimization
import de.cau.cs.kieler.ptolemy.klighd.transformation.Ptolemy2KGraphTransformation
import de.cau.cs.kieler.ptolemy.klighd.transformation.Ptolemy2KGraphVisualization
import de.cau.cs.kieler.ptolemy.klighd.transformation.comments.CommentsAttachor
import de.cau.cs.kieler.ptolemy.klighd.transformation.comments.CommentsExtractor
import org.eclipse.elk.alg.layered.options.LayeredOptions
import org.eclipse.elk.alg.layered.options.NodePlacementStrategy
import org.eclipse.elk.core.labels.LabelManagementOptions
import org.eclipse.elk.core.options.CoreOptions
import org.ptolemy.moml.DocumentRoot

/**
 * Synthesis for turning Ptolemy models into KGraphs.
 * 
 * @author cds
 */
public class PtolemyDiagramSynthesis extends AbstractDiagramSynthesis<DocumentRoot> {
    
    public static val ID = "de.cau.cs.kieler.ptolemy.klighd.PtolemyDiagramSynthesis"
    
    
    //////////////////////////////////////////////////////////////////////////////////////
    // Transformation Options
        
    public static val SynthesisOption SHOW_RELATIONS = SynthesisOption::createCheckOption(
        "Relations", false)
        
    public static val SynthesisOption SHOW_DIRECTORS = SynthesisOption::createCheckOption(
        "Directors", true)
        
    public static val SynthesisOption SHOW_PROPERTIES = SynthesisOption::createCheckOption(
        "Parameters", true)
        
    public static val SynthesisOption SHOW_PORT_LABELS = SynthesisOption::createChoiceOption(
        "Port Labels", ImmutableList::of(
            LabelDisplayStyle.ALL.toString(),
            LabelDisplayStyle.SELECTED.toString(),
            LabelDisplayStyle.NONE.toString()),
        LabelDisplayStyle.NONE.toString())
    
    private static val SHOW_COMMENTS_ALL = "All";
    private static val SHOW_COMMENTS_SELECTED = "Selected";
    private static val SHOW_COMMENTS_NONE = "None";
    public static val SynthesisOption SHOW_COMMENTS = SynthesisOption::createChoiceOption(
        "Comments", ImmutableList::of(
            SHOW_COMMENTS_ALL,
            SHOW_COMMENTS_SELECTED,
            SHOW_COMMENTS_NONE),
        "All")
        
    public static val SynthesisOption COMMENT_ATTACHMENT_HEURISTIC =
        SynthesisOption::createCheckOption("Attach to nodes", true) 
        
    public static val SynthesisOption ATTACHMENT_HEURISTIC = SynthesisOption::createChoiceOption(
        "Attachment heuristic", 
        ImmutableList::of("Smallest distance", "Comment alignment", "Find label name plain", 
                "Find label name", "Find label name w/o two attached"), "Smallest distance")
        
    public static val SynthesisOption FLATTEN = SynthesisOption::createCheckOption(
        "Flatten Composite Actors", false)
    
    /** Whether hierarchical nodes should initially be collapsed after transformation. */
    public static val SynthesisOption INITIALLY_COLLAPSED = SynthesisOption::createCheckOption(
        "Collapse Composite Actors", true)
        
    public static val SynthesisOption COMPOUND_NODE_ALPHA = SynthesisOption::createRangeOption(
        "Nested model darkness", 0f, 255f, 30f)
                
    /** Whether to transform state machines. Currently the option is not exposed to the user 
     * but can be set programmatically as synthesis options, e.g. for batch export. */
    public static val SynthesisOption TRANSFORM_STATES = SynthesisOption::createCheckOption(
        "Transform states", true)
    
    
    /**
     * Diagram options.
     */
    override getDisplayedSynthesisOptions() {
        return ImmutableList.of(
            SynthesisOption.createSeparator("Visible Elements"),
            SHOW_RELATIONS,
            SHOW_DIRECTORS,
            SHOW_PROPERTIES,
            SHOW_PORT_LABELS,
            SHOW_COMMENTS,
            SynthesisOption.createSeparator("Comments"),
            COMMENT_ATTACHMENT_HEURISTIC,
            SynthesisOption.createSeparator("Hierarchy"),
            FLATTEN,
            INITIALLY_COLLAPSED,
            COMPOUND_NODE_ALPHA)
    }
    
    /**
     * Layout options.
     */
    override getDisplayedLayoutOptions() {
        return ImmutableList::of(
            DiagramSyntheses.specifyLayoutOption(LayeredOptions.NODE_PLACEMENT_STRATEGY,
                ImmutableList::copyOf(NodePlacementStrategy::values)),
            DiagramSyntheses.specifyLayoutOption(CoreOptions::SPACING_NODE_NODE,
                ImmutableList::of(0, 255))
        )
    }
    
    /**
     * Container class for easy handling of synthesis options.
     */
    public static final class Options {
        public var boolean relations
        public var boolean directors
        public var boolean properties
        public var LabelDisplayStyle portLabels
        public var LabelDisplayStyle comments
        
        public var boolean commentsLabelManage
        public var boolean commentsAttach
        
        public var boolean flatten
        public var boolean initiallyCollapsed
        public var int compoundNodeAlpha
        
        public var boolean transformStates
        
        new(PtolemyDiagramSynthesis s) {
            relations = s.getBooleanValue(SHOW_RELATIONS)
            directors = s.getBooleanValue(SHOW_DIRECTORS)
            properties = s.getBooleanValue(SHOW_PROPERTIES)
            portLabels = LabelDisplayStyle.fromDisplayString(
                s.getObjectValue(SHOW_PORT_LABELS).toString())
            comments = LabelDisplayStyle.fromDisplayString(
                s.getObjectValue(SHOW_COMMENTS).toString())
            
            commentsAttach = s.getBooleanValue(COMMENT_ATTACHMENT_HEURISTIC)
            commentsLabelManage = s.getObjectValue(SHOW_COMMENTS) == SHOW_COMMENTS_SELECTED
            
            flatten = s.getBooleanValue(FLATTEN)
            initiallyCollapsed = s.getBooleanValue(INITIALLY_COLLAPSED)
            compoundNodeAlpha = s.getIntValue(COMPOUND_NODE_ALPHA)
            
            transformStates = s.getBooleanValue(TRANSFORM_STATES)
        }
    }
        
                
    //////////////////////////////////////////////////////////////////////////////////////
    // Transformation
    
    // The parts of our transformation
    @Inject Ptolemy2KGraphTransformation transformation
    @Inject Ptolemy2KGraphOptimization optimization
    @Inject Ptolemy2KGraphVisualization visualization
    @Inject CommentsExtractor commentsExtractor
    @Inject CommentsAttachor commentsAttachor
   
    override transform(DocumentRoot model) {
        // Capture options
        val options = new Options(this)
        val extractComments = options.comments != LabelDisplayStyle.NONE;
        
        // Transform, optimize, and visualize
        val kgraph = transformation.transform(model, this, options)
        optimization.optimize(kgraph, options, if (extractComments) commentsExtractor else null, this)
        visualization.visualize(kgraph, options)
        
        // If comments should be shown, we want them to be attached properly. Do that now, because we
        // know the node sizes only after the visualization
        if (options.commentsAttach) {
            commentsAttachor.attachComments(kgraph)
        }
        
        // Label managers
        setupLabelManagement(kgraph, options);
        
        return kgraph
    }
    
    private def void setupLabelManagement(KNode kgraph, Options options) {
        val labelManager = new ListLabelManager();
        
        if (options.portLabels == LabelDisplayStyle.SELECTED) {
            labelManager.addLabelManager(TypeConditionLabelManager.wrapForPortLabels(new HidingLabelManager()));
        }
        
        if (options.comments == LabelDisplayStyle.SELECTED) {
            val commentLabelManager = TypeConditionLabelManager.wrapForCommentLabels(new TruncatingLabelManager()
                .truncateAfterFirstWords(5)
                .setMode(AbstractKlighdLabelManager.Mode.ALWAYS_ON))
            labelManager.addLabelManager(commentLabelManager);
        }
        
        if (!labelManager.labelManagers.isEmpty()) {
            kgraph.setLayoutOption(LabelManagementOptions.LABEL_MANAGER, labelManager);
        }
    }
    
}