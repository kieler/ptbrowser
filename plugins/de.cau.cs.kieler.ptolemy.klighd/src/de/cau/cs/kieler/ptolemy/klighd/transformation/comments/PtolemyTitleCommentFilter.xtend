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
import de.cau.cs.kieler.ptolemy.klighd.transformation.extensions.MarkerExtensions
import org.eclipse.elk.core.comments.IDataProvider
import org.eclipse.elk.core.comments.IFilter

import static de.cau.cs.kieler.ptolemy.klighd.PtolemyProperties.*

/**
 * Passes judgement on a comment's eligibility for attachment based on whether it is considered a title
 * comment or not. There are two ways to be considered a title comment. First, the comment is a type
 * of title comment in Ptolemy. And second, it has the largest font size of all comments. We only
 * expect the latter to appear on the graph's top level.
 * 
 * <p>
 * The largest font size thing probably deserves a bit more details. To be considered a title comment
 * based on the font size, a comment must match a few conditions. First, it must have the largest font
 * size. Second, it has to be the only comment with that font size. Third, it must not be the only
 * comment. And finally, its font size needs to be larger than the default font size.
 * </p>
 */
final class PtolemyTitleCommentFilter implements IFilter<KNode> {
    
    @Inject extension MarkerExtensions
    
    /** The comment with the largest font size in the current graph. */
    var KNode largestFontSizeComment = null;
    /** Whether to decide only based on the font size, even if a comment is marked as title. */
    var decideBasedOnFontSizeOnly = false;
    
    
    /**
     * Once this method is called, the filter will disregard whether a comment is marked as title and
     * only regard comments as title based on their font size. This should really only be necessary
     * for evaluations.
     */
    def void decideBasedOnFontSizeOnly() {
        decideBasedOnFontSizeOnly = true;
    }
    
    /**
     * Returns the comment determined by the filter to be the title comment. Can only be non-null
     * between calls to {@code preprocess(...)} and {@code cleanup()}.
     */
    def KNode getChosenComment() {
        return largestFontSizeComment;
    }
    
    
    override void preprocess(IDataProvider<KNode, ?> dataProvider, boolean includeHierarchy) {
        // We require title comments to have a font size larger than the default font size
        var int largestFontSize = COMMENT_FONT_SIZE.^default;
        var int numberOfComments = 0;
        
        // Iterate over all the comments
        for (node : dataProvider.provideComments()) {
            // Make sure the node is a comment
            numberOfComments++;
            val fontSize = node.getProperty(COMMENT_FONT_SIZE);
            
            if (fontSize > largestFontSize) {
                // We have a new biggest font size!
                largestFontSize = fontSize;
                largestFontSizeComment = node;
                
            } else if (fontSize == largestFontSize) {
                // We don't have a single comment with the biggest font size anymore
                largestFontSizeComment = null;
            }
        }
        
        // If we only encountered a single comment, we don't consider it a title comment
        if (numberOfComments == 1) {
            largestFontSizeComment = null;
        }
    }
    
    override eligibleForAttachment(KNode comment) {
        return comment != largestFontSizeComment
            && (decideBasedOnFontSizeOnly || !comment.markedAsTitleNode);
    }
    
    override void cleanup() {
        largestFontSizeComment = null;
    }
    
}