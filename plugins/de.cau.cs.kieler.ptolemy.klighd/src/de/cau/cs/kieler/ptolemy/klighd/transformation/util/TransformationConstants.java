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

package de.cau.cs.kieler.ptolemy.klighd.transformation.util;

import java.util.Map;
import java.util.Set;

import com.google.common.collect.Maps;
import com.google.common.collect.Sets;

/**
 * Contains constants used during the transformations. This class is not to be instantiated.
 * 
 * <p><em>Note:</em> FindBugs has problems with the arrays defined herein. However, we don't care
 * too much about that.</p>
 * 
 * @author cds
 * @kieler.rating proposed yellow cds 2015-02-23
 */
public final class TransformationConstants {
    
    // PORT NAMES
    
    /** Possible names for input ports. Used to infer port types during the transformation. */
    public static final String[] PORT_NAMES_INPUT = {"in", "input", "incomingPort", "sceneGraphIn"};
    
    /** Possible names for output ports. Used to infer port types during the transformation. */
    public static final String[] PORT_NAMES_OUTPUT = {"out", "output", "outgoingPort", "sceneGraphOut"};
    
    /** Regular expression for the separator character used in port names. */
    public static final String PORT_NAME_SEPARATOR_REGEX = "\\.";
    
    
    // PORT TYPES
    
    /** Name for an annotation that marks a port as being a multiport. */
    public static final String IS_MULTIPORT = "_multiport";
    
    /** Name of an annotation that marks a port as being a ParameterPort instance. */
    public static final String IS_PARAMETER_PORT = "_parameterPort";
    
    /** Name of an annotation that marks a port as being an IOPort instance. */
    public static final String IS_IO_PORT = "_ioPort";
    
    /** Class of a refinement port in modal models. */
    public static final String PORT_CLASS_MODAL_MODEL_PORT = "ptolemy.domains.modal.modal.ModalPort";
    
    /** Class of a refinement port in FSM modal models. */
    public static final String PORT_CLASS_FSM_MODAL_MODEL_PORT = "ptolemy.domains.fsm.modal.ModalPort";
    
    /** Class of a refinement port in modal models. */
    public static final String PORT_CLASS_REFINEMENT_PORT = "ptolemy.domains.modal.modal.RefinementPort";

    /** Class of a refinement port in FSM modal models. */
    public static final String PORT_CLASS_FSM_REFINEMENT_PORT =
            "ptolemy.domains.fsm.modal.RefinementPort";
    
    
    // ENTITY TYPES
    
    /** Class of an entity that houses a finite state machine. */
    public static final String ENTITY_CLASS_FSM = "ptolemy.domains.modal.kernel.FSMActor";
    
    /** Class of an entity that houses a modal model. */
    public static final String ENTITY_CLASS_MODAL_MODEL = "ptolemy.domains.modal.modal.ModalModel";
    
    /** Class of a further entity that houses a modal model. */
    public static final String ENTITY_CLASS_FSM_MODAL_MODEL = "ptolemy.domains.fsm.modal.ModalModel";
    
    /** Class of an entity that is the controller of a modal model. */
    public static final String ENTITY_CLASS_MODEL_CONTROLLER =
            "ptolemy.domains.modal.modal.ModalController";
    
    public static final String ENTITY_CLASS_FSM_MODEL_CONTROLLER =
            "ptolemy.domains.fsm.modal.ModalController";
    
    /** Class of an entity that is a refinement for modal model states. */
    public static final String ENTITY_CLASS_STATE_REFINEMENT = "ptolemy.domains.modal.modal.Refinement";
    
    /** Class of an entity that is a state machine state. */
    public static final String ENTITY_CLASS_STATE = "ptolemy.domains.modal.kernel.State";

    /** Class of an entity that is an FSM state machine state. */
    public static final String ENTITY_CLASS_FSM_STATE = "ptolemy.domains.fsm.kernel.State";
    
    /** Class of an entity that is an FSM state machine state. */
    public static final String ENTITY_CLASS_FMV_STATE = "ptolemy.domains.modal.kernel.fmv.FmvState";
    
    /** Classes of entities that occur in the models shipping with ptolemy, 
     *  for which it hasn't been checked what they really are. Most of them are probably states. */
    public static final Set<String> ENTITY_MAYBE_STATE_NOT_SURE =
            Sets.newHashSet("ptolemy.domains.modal.kernel.InterfaceAutomaton",
                    "ptolemy.domains.modal.kernel.ia.InterfaceAutomaton",
                    "ptolemy.domains.modal.modal.ModalRefinement",
                    "ptolemy.domains.modal.kernel.fmv.FmvAutomaton",
                    "ptolemy.domains.modal.modal.TransitionRefinement",
                    "ptolemy.domains.modal.demo.ABP.Receiver");
    
    /** Class of an entity that is a Const actor. */
    public static final String ENTITY_CLASS_CONST = "ptolemy.actor.lib.Const";
    
    /** Class of an entity that is a String Const actor. */
    public static final String ENTITY_CLASS_STRING_CONST = "ptolemy.actor.lib.StringConst";
    
    /** Class of an entity that is an Expression actor. */
    public static final String ENTITY_CLASS_EXPRESSION = "ptolemy.actor.lib.Expression";
    
    /** Class of an entity that is a Sample Delay actor. */
    public static final String ENTITY_CLASS_SAMPLE_DELAY = "ptolemy.domains.sdf.lib.SampleDelay";
    
    /** Class of an entity that is a Non-Strict Delay actor. */
    public static final String ENTITY_CLASS_NONSTRICT_DELAY = "ptolemy.domains.sr.lib.NonStrictDelay";
    
    /** Class of an entity that is a Logic Function actor. */
    public static final String ENTITY_CLASS_LOGIC_FUNTION = "ptolemy.actor.lib.logic.LogicFunction";

    /** Class of an entity that is a Unary Math Function actor. */
    public static final String ENTITY_CLASS_UNARY_MATH_FUNTION = "ptolemy.actor.lib.UnaryMathFunction";
    
    /** Class of an entity that is a Trig Function actor. */
    public static final String ENTITY_CLASS_TRIG_FUNTION = "ptolemy.actor.lib.TrigFunction";
    
    
    // ENTITY NAMES
    
    /** Name of the entity that contains the modal model states. */
    public static final String ENTITY_NAME_MODAL_CONTROLLER = "_Controller";
    
    
    // ANNOTATION TYPES
    
    /** Trype of attributes. */
    public static final String ANNOTATION_TYPE_ATTRIBUTE = "ptolemy.kernel.util.Attribute";
    
    /** Type of annotations that describe a comment. */
    public static final String ANNOTATION_TYPE_TEXT_ATTRIBUTE =
            "ptolemy.vergil.kernel.attributes.TextAttribute";
    
    /** Type of annotations that hold the text of comments. */
    public static final String ANNOTATION_TYPE_STRING_ATTRIBUTE = "ptolemy.kernel.util.StringAttribute";
    
    /** Type of annotations that define parameters of models. */
    public static final String ANNOTATION_TYPE_PARAMETER = "ptolemy.data.expr.Parameter";
    
    /** Type of annotations that define diagram titles. */
    public static final String ANNOTATION_TYPE_TITLE = "ptolemy.vergil.basic.export.web.Title";
    
    /** Type of annotations that define diagram html-titles. */
    public static final String ANNOTATION_TYPE_HTML_TITLE = "ptolemy.vergil.basic.export.html.Title";
    
    /** Type of annotations that define lattice ontology solvers*/
    public static final String ANNOTATION_TYPE_LATTICE_ONTOLOGY_SOLVER = 
            "ptolemy.data.ontologies.lattice";
    
    /** Type of annotations that define documentation attributes. */
    public static final String ANNOTATION_TYPE_DOCUMENTATION = 
            "ptolemy.vergil.kernel.attributes.DocumentationAttribute";
    
    // ANNOTATION NAMES
    
    /**
     * Name for an annotation describing where a model element originally came from if it was
     * transformed from another model.
     */
    public static final String ANNOTATION_LANGUAGE = "_language";
    
    /**
     * Value of the {@link #ANNOTATION_LANGUAGE} annotation identifying elements transformed from a
     * Ptolemy model.
     */
    public static final String ANNOTATION_LANGUAGE_PTOLEMY = "ptolemy";
    
    /**
     * Name for an annotation describing the original class name of an element imported from a
     * Ptolemy model.
     */
    public static final String ANNOTATION_PTOLEMY_CLASS = "_ptolemyClass";
    
    /**
     * Name of the annotation that specifies the name of the element a comment is explicitly attached to.
     */
    public static final String ANNOTATION_RELATIVE_TO ="relativeTo";
    
    /**
     * Name of the annotation that specifies the type of the element a comment is explicitly attached to.
     */
    public static final String ANNOTATION_RELATIVE_TO_ELEMENT_NAME = "relativeToElementName";
    
    /** Name of the annotation that holds the text of a comment. */
    public static final String ANNOTATION_COMMENT_TEXT = "text";
    
    /** Name of the annotation that holds the font size of a comment. */
    public static final String ANNOTATION_FONT_SIZE = "textSize";
    
    /** Name of the annotation that holds an element's location. */
    public static final String ANNOTATION_LOCATION = "_location";
    
    /** Name of the annotation that holds the anchor whose position is defined by the location. */
    public static final String ANNOTATION_ANCHOR = "anchor";
    
    /** Name of the annotation that holds the name of a state's refinement. */
    public static final String ANNOTATION_REFINEMENT_NAME = "refinementName";
    
    /** Name of the annotation that holds an annotation text for a state machine relation. */
    public static final String ANNOTATION_ANNOTATION = "annotation";
    
    /** Name of the annotation that holds the guard expression for a state machine relation. */
    public static final String ANNOTATION_GUARD_EXPRESSION = "guardExpression";
    
    /** Name of the annotation that holds the output actions for a state machine relation. */
    public static final String ANNOTATION_OUTPUT_ACTIONS = "outputActions";
    
    /** Name of the annotation that holds the set actions for a state machine relation. */
    public static final String ANNOTATION_SET_ACTIONS = "setActions";
    
    /** Name of the annotation that identifies reset transitions. */
    public static final String ANNOTATION_RESET_TRANSITION = "reset";
    
    /** Name of the annotation that identifies reset transitions. */
    public static final String ANNOTATION_PREEMPTIVE_TRANSITION = "preemptive";
    
    /** Name of the annotation that identifies reset transitions. */
    public static final String ANNOTATION_IMMEDIATE_TRANSITION = "immediate";
    
    /** Name of the annotation that identifies reset transitions. */
    public static final String ANNOTATION_DEFAULT_TRANSITION = "defaultTransition";
    
    /** Name of the annotation that identifies reset transitions. */
    public static final String ANNOTATION_ERROR_TRANSITION = "errorTransition";
    
    /** Name of the annotation that identifies reset transitions. */
    public static final String ANNOTATION_NONDETERMINISTIC_TRANSITION = "nondeterministic";
    
    /** Map of value displaying classes to the properties the value is stored in. */
    public static final Map<String, String> VALUE_DISPLAY_MAP = Maps.newHashMap();
    static {
        VALUE_DISPLAY_MAP.put(ENTITY_CLASS_CONST, "value");
        VALUE_DISPLAY_MAP.put(ENTITY_CLASS_STRING_CONST, "value");
        VALUE_DISPLAY_MAP.put(ENTITY_CLASS_EXPRESSION, "expression");
        VALUE_DISPLAY_MAP.put(ENTITY_CLASS_SAMPLE_DELAY, "initialOutputs");
        VALUE_DISPLAY_MAP.put(ENTITY_CLASS_NONSTRICT_DELAY, "initialValue");
        VALUE_DISPLAY_MAP.put(ENTITY_CLASS_LOGIC_FUNTION, "function");
        VALUE_DISPLAY_MAP.put(ENTITY_CLASS_TRIG_FUNTION, "function");
        VALUE_DISPLAY_MAP.put(ENTITY_CLASS_UNARY_MATH_FUNTION, "function");
    }
    
    
    /**
     * This class is not meant to be instantiated.
     */
    private TransformationConstants() {
        // This space intentionally left mostly blank
    }
    
}
