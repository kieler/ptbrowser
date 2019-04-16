  
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
package de.cau.cs.kieler.ptolemy.klighd.transformation.comments

import com.google.common.collect.ArrayListMultimap
import com.google.common.collect.Multimap
import com.google.inject.Inject
import de.cau.cs.kieler.klighd.kgraph.KNode
import de.cau.cs.kieler.klighd.kgraph.util.KGraphUtil
import de.cau.cs.kieler.klighd.syntheses.AbstractDiagramSynthesis
import de.cau.cs.kieler.ptolemy.klighd.transformation.extensions.AnnotationExtensions
import de.cau.cs.kieler.ptolemy.klighd.transformation.extensions.MarkerExtensions
import org.eclipse.elk.core.util.Pair
import org.eclipse.emf.ecore.util.FeatureMap
import org.eclipse.emf.ecore.xmi.XMLResource
import org.eclipse.emf.ecore.xml.type.AnyType
import org.ptolemy.moml.PropertyType

import static de.cau.cs.kieler.ptolemy.klighd.PtolemyProperties.*
import static de.cau.cs.kieler.ptolemy.klighd.transformation.util.TransformationConstants.*

/**
 * Extracts comments from the model and turns them into special comment nodes.
 * 
 * <p>In Ptolemy, certain annotations in a model are like comments in source code.
 * There are two ways how they can be represented in MOML:</p>
 * 
 * <ol>
 *   <li>Using a property of type "ptolemy.vergil.kernel.attributes.TextAttribute"
 *       with another property named "text", as follows:
 *     <pre>
 *        &lt;property
 *              name="Annotation2"
 *              class="ptolemy.vergil.kernel.attributes.TextAttribute"&gt;
 *              
 *              &lt;property
 *                      name="text"
 *                      class="ptolemy.kernel.util.StringAttribute"
 *                      value="This is my annotation's text."&gt;
 *              &lt;/property&gt;
 *              &lt;property
 *                      name="_location"
 *                      class="ptolemy.kernel.util.Location"
 *                      value="[140.0, 440.0]"&gt;
 *              &lt;/property&gt;
 *        &lt;/property&gt;
 *     </pre>
 *   </li>
 *   
 *   <li>Using a property of type "ptolemy.kernel.util.Attribute" with an SVG
 *       as its "_iconDescription" property, as follows:
 *     <pre>
 *        &lt;property
 *              name="annotation3"
 *              class="ptolemy.kernel.util.Attribute"&gt;
 *              
 *              &lt;property
 *                      name="_iconDescription"
 *                      class="ptolemy.kernel.util.SingletonConfigurableAttribute"&gt;
 *                      
 *                      &lt;configure&gt;&lt;svg&gt;
 *                              &lt;text x="20" y="20" style="..."&gt;
 *                                      This is my annotation's text.
 *                              &lt;/text&gt;
 *                      &lt;/svg&gt;&lt;/configure&gt;
 *              &lt;/property&gt;
 *              &lt;property
 *                      name="_location"
 *                      class="ptolemy.kernel.util.Location"
 *                      value="[325.0, 10.0]"&gt;
 *              &lt;/property&gt;
 *        &lt;/property&gt;
 *     </pre>
 *   </li>
 * </ol>
 *      
 * <p>while the first version is straightforward, the latter version causes a whole
 * lot of problems. The {@code configure} element is a mixed
 * element, which means that it can contain anything, not just XML. However, it
 * does contain XML (usually an {@code svg} element and its children), which
 * disturbs the quiet peace of the parser. (which, in turn, disturbs my quiet peace.)
 * The {@code configure} element and its children are then dropped by the parser
 * during the transformation and are added to a list of unknown features. Recovering
 * such comments is one of the two tasks of this handler.</p>
 * 
 * <p>The second task is recognizing links between comments and model elements. Such
 * links indicate that a comment is providing additional information for a model
 * element, and should be preserved. In the MoML file, such a link is represented by
 * the following property:</p>
 * 
 * <pre>
 *   &lt;property
 *         name="_location"
 *         class="ptolemy.kernel.util.RelativeLocation"
 *         value="[-195.0, -80.0]"&gt;
 *         
 *         &lt;property
 *               name="relativeTo"
 *               class="ptolemy.kernel.util.StringAttribute"
 *               value="Const"/&gt;
 *         &lt;property
 *               name="relativeToElementName"
 *               class="ptolemy.kernel.util.StringAttribute"
 *               value="entity"/&gt;
 *   &lt;/property&gt;
 * </pre>
 * 
 * <p>That is, the annotation's {@code _location} property is extended by two additional
 * properties that define that the location is to be interpreted relative to a given
 * model element. So far, we only support linking comments to entities, but that could
 * well be changed.</p>
 * 
 * @see CommentsAttachor
 * @author cds
 */
class CommentsExtractor {
    
    /** Marking nodes. */
    @Inject extension AnnotationExtensions
    /** Marking nodes. */
    @Inject extension MarkerExtensions
    
    
    ////////////////////////////////////////////////////////////////////////////////////////////////////
    // Comment Extraction
    
    /**
     * Extracts the comments attached as annotations to the given node and turns them into proper
     * nodes that are children of the given node.
     * 
     * @param root the root node.
     * @param diagramSynthesis the diagram synthesis that uses this class; used to map Ptolemy model
     *                         objects to the nodes created for them.
     * @return extracted comment nodes, to be passed to the attachment heuristic later.
     */
    def Multimap<KNode, KNode> extractComments(KNode root,
        AbstractDiagramSynthesis<?> diagramSynthesis) {
        
        // Maps nodes to those of their child nodes that represent comments
        val Multimap<KNode, KNode> createdCommentNodes =  ArrayListMultimap.create()
        
        // Iterate through the node's annotations looking for comments
        for (annotation : root.annotations) {
            if ((annotation.class_ ?: "").equals(ANNOTATION_TYPE_TEXT_ATTRIBUTE)) {
                // Create comment node and keep annotations and text size of the original comment
                val commentNode = addCommentNode(root,
                    annotation.getAnnotationValue(ANNOTATION_COMMENT_TEXT) ?: "", 
                    annotation.getAnnotationValue(ANNOTATION_FONT_SIZE) ?: "14",
                    createdCommentNodes)
                commentNode.annotations += annotation.annotations
                diagramSynthesis.associateWith(commentNode, annotation)
            } else if ((annotation.class_ ?: "").equals(ANNOTATION_TYPE_ATTRIBUTE)) {
                // Check if there is an _iconDescription attribute
                val iconDescription = annotation.getAnnotation("_iconDescription")
                
                if (iconDescription !== null) {
                    // We may have a shot at retrieving the comment text
                    val commentDetails = restoreCommentTextFromIconDescription(iconDescription)
                    
                    if (commentDetails !== null && commentDetails.first !== null) {
                        // We were successful; add a comment node
                        val commentNode = addCommentNode(root, commentDetails.first,
                            extractFontSize(commentDetails.second),
                            createdCommentNodes)
                        commentNode.annotations += annotation.annotations
                        diagramSynthesis.associateWith(commentNode, annotation)
                    }
                }
            }
        }
 
        // Insert title comments into the list of comment nodes
        for (child : root.children) {
            if (child.markedAsTitleNode){
                createdCommentNodes.put(root,child) 
            }
        }
 
        // Recurse into child compound nodes
        for (child : root.children) {
            if (!child.children.empty) {
                extractComments(child, diagramSynthesis)
            }
        }
        
        return createdCommentNodes
    }
    
    /**
     * Extracts the font size of a comment that was saved as an SVG graphic.
     * 
     * @param style the value of the {@code style} attribute of an attribute. 
     * @return the font size of the element.
     */
    def private String extractFontSize(String style){
        val String pattern = "font-size(\\s*):(\\s*)(\\d+).*"
        
        return style.replaceAll(pattern, "$3")
    }
    
    /**
     * Tries to restore the text of a comment that was not saved as a regular comment attribute, but
     * as an SVG graphic.
     * 
     * @param iconDescription the {@code _iconDescription} attribute of the attribute that might be a
     *                        comment. This is where we will look for the SVG graphic in.
     * @return a pair consisting of the text and the style of the text, if present, or {@code null} if
     *         the text could not be restored.
     */
    def private Pair<String, String> restoreCommentTextFromIconDescription(
        PropertyType iconDescription) {
        
        // For this stuff to work, we need to get our hands at the XMLResource that loaded the icon
        // description, because that has a map of features that couldn't be parsed
        if (!(iconDescription.eResource instanceof XMLResource)) {
            return null
        }
        val xmlResource = iconDescription.eResource as XMLResource
        
        // Check if the icon description has a <configure> element
        if (iconDescription.configure.empty) {
            return null
        }
        val configureElement = iconDescription.configure.get(0)
        
        // Check if there are unknown features associated with the <configure> element
        val unknownFeature = xmlResource.EObjectToExtensionMap.get(configureElement)
        if (unknownFeature === null) {
            return null
        }
        
        val svgElement = findUnknownFeature(unknownFeature.mixed, "svg")
        if (svgElement === null) {
            return null
        }
        
        val textElement = findUnknownFeature(svgElement.mixed, "text")
        if (textElement === null) {
            return null
        }
        
        // We've found a text element; retrieve its character data
        if (textElement.mixed.empty) {
            return null
        }
        
        val data = textElement.mixed.get(0).value
        if (!(data instanceof String)) {
            return null
        } else {
            val Pair<String, String> commentDetails = Pair.create();
            
            // Remember the text
            commentDetails.first = data as String;
            
            // Try to extract the style as well
            for (var i = 0; i < textElement.anyAttribute.size; i++) {
                val attribute = textElement.anyAttribute.get(i);
                
                if (attribute.EStructuralFeature.name == "style") {
                    commentDetails.second = attribute.value as String;
                }
            }
            
            return commentDetails;
        }
    }
    
    /**
     * Creates a comment node and adds it to the given parent node. Also adds it to the list of
     * created comment nodes.
     * 
     * @param parent parent of the new comment node.
     * @param text the comment text to be displayed by the comment node.
     * @param fontSize the font size of the comment's text.
     * @param createdCommentNodes map of created comment nodes this node will be placed in.
     * @return the created comment node.
     */
    def private KNode addCommentNode(KNode parent, String text, String fontSize,
        Multimap<KNode, KNode> createdCommentNodes) {
            
        val commentNode = KGraphUtil.createInitializedNode()
        
        commentNode.setProperty(COMMENT_FONT_SIZE, Integer.parseInt(fontSize))
        commentNode.markAsComment()
        
        parent.children += commentNode
        createdCommentNodes.put(parent, commentNode)
        
        // We'll be using a label to display the comment's text
        val commentLabel = KGraphUtil.createInitializedLabel(commentNode);
        commentLabel.text = text;
        
        return commentNode
    }

    /**
     * Checks if the feature map contains a feature of the given name and returns that.
     * 
     * @param features the feature map to search through.
     * @param name name of the feature to look for.
     * @return the feature or {@code null} if none could be found with that name.
     */
    def private AnyType findUnknownFeature(FeatureMap features, String name) {
        for (entry : features) {
            if (entry.EStructuralFeature.name.equals(name)) {
                if (entry.value instanceof AnyType) {
                    return entry.value as AnyType
                }
            }
        }
        
        return null
    }
}
