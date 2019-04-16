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

import com.google.inject.Guice
import com.google.inject.Inject
import de.cau.cs.kieler.klighd.kgraph.KNode
import de.cau.cs.kieler.ptolemy.klighd.PtolemyProperties
import de.cau.cs.kieler.ptolemy.klighd.transformation.extensions.LabelExtensions
import org.eclipse.elk.core.comments.CommentAttacher
import org.eclipse.elk.core.comments.DistanceMatcher
import org.eclipse.elk.core.comments.NodeReferenceMatcher
import org.eclipse.elk.core.comments.SizeFilter
import org.eclipse.elk.core.comments.TextPrefixFilter

/**
 * Tries to infer the attachments between comment nodes and the elements they are supposed to describe.
 * There are two cases here:</p>
 *
 * <ol>
 *   <li>The model contains explicit links between at least one comment and model element. In this case,
 *   we assume that the model developer added all the links he wants explicitly and only transform such
 *   links into the our way of representing them. We recognize explicit links through the fact that the
 *   {@link CommentsExtractor} has already turned them into edges.</li>
 *
 *   <li>The model does not contain any such explicit link. In this case, a heuristic is applied to each
 *   comment, trying to find the entity it is probably referring to.
 * </ol>
 *
 * <p>The heuristic can be applied in the first case as well. The explicit links will not be touched,
 * then; only unlinked comments will be considered for attachment.</p>
 *
 * @see CommentsExtractor
 * @author cds
 */
class CommentsAttachor {

    @Inject extension LabelExtensions

    /** Maximum distance for two objects to be considered close enough for attachment. */
    val double maxAttachmentDistance = 50;
    /** Maximum attachment distance used by the node reference heuristic. */
    val double maxAttachmentDistanceForReferenceHeuristic = 30;
    /** The maximum area of a comment to still be considered attacheable. */
    val double maxCommentArea = 62000;
//    /** Maximum distance for two objects to be considered to be aligned. */
//    val double maxAlignmentDistance = 2001;


    /**
     * Invokes KIML's comment attachment framework on the given graph.
     *
     * @param graph the graph to perform comment attachment on.
     */
    def void attachComments(KNode graph) {
        // Create injected class instances
        val injector = Guice.createInjector();
        
        val dataProvider =  injector.getInstance(typeof(KGraphDataProvider)).withGraph(graph).cached()
        val boundsProvider = injector.getInstance(typeof(PtolemyBoundsProvider)).cached();
        val explicitAttachmentProvider = injector.getInstance(typeof(ExplicitPtolemyAttachmentProvider));
        val titleCommentFilter = injector.getInstance(typeof(PtolemyTitleCommentFilter));
        
        val attacher = new CommentAttacher<KNode, KNode>()
            .withBoundsProvider(boundsProvider)
            .withExplicitAttachmentProvider(explicitAttachmentProvider)
            .withAttachmentDecider(new ReferencePreferringAttachmentDecider())
            
            // Filters
            .addFilter(titleCommentFilter)
            .addFilter(new TextPrefixFilter<KNode>()
                .withCommentTextProvider(c | c.getProperty(PtolemyProperties.COMMENT_TEXT))
                .addPrefix("Author")  // Also matches "Authors"
                .addPrefix("Demo created by")
                .addPrefix("This model ")
                .addPrefix("This submodel ")
                .addPrefix("This example ")
                .addPrefix("This demo ")
                .addPrefix("Model of ")
            )
            .addFilter(new SizeFilter<KNode>()
                .withBoundsProvider(boundsProvider)
                .withMaximumArea(maxCommentArea)
            )
            
            // Matchers
            .addMatcher(new NodeReferenceMatcher<KNode, KNode>()
                .withCommentTextProvider(c | c.getProperty(PtolemyProperties.COMMENT_TEXT))
                .withTargetNameProvider(n | n.name)
                .withBoundsProvider(boundsProvider)
                .withMaximumAttachmentDistance(maxAttachmentDistanceForReferenceHeuristic)
            )
            .addMatcher(new DistanceMatcher<KNode, KNode>()
                .withBoundsProvider(boundsProvider)
                .withMaximumAttachmentDistance(maxAttachmentDistance)
            )
//            .addMatcher(new AlignmentMatcher<KNode, KNode>()
//                .withBoundsProvider(boundsProvider)
//                .withMaximumAlignmentOffset(maxAlignmentDistance)
//            )
        
        // Run comment attachment
        attacher.attachComments(dataProvider);
    }


    ////////////////////////////////////////////////////////////////////////////////////////////////////
    // DEBUGGING UTILITIES
    
//    /**
//     * Saves the given KGraph as an SVG in one of our excellent debugging locations.
//     * 
//     * @param root root node of the KGraph to save.
//     */
//    private def void saveDebugSvg(KNode root) {
//        // Iterate over the children and find the bounds of the diagram
//        var Rectangle2D.Double bounds = null;
//        for (child : root.children) {
//            if (child.ptolemyBounds.x != 2e20) {
//                if (bounds == null) {
//                    bounds = new Rectangle2D.Double();
//                    bounds.setRect(child.ptolemyBounds);
//                } else {
//                    bounds.add(child.ptolemyBounds);
//                }
//            }
//
//            if (!child.children.empty) {
//                saveDebugSvg(child);
//            }
//        }
//
//        // It may happen that none of the children have proper positions, in which case we don't have
//        // anything to draw
//        if (bounds === null) {
//            return;
//        }
//
//        // Make the bounds start at (0,0)
//        bounds.width += bounds.x + 5;
//        bounds.height += bounds.y + 5;
//        bounds.x = 0;
//        bounds.y = 0;
//
//        // Create an SVG graphics object to draw on
//        val graphics = SVGGeneratorManager.createGraphics(
//            "de.cau.cs.kieler.klighd.piccolo.svggen.freeHEPExtended", bounds, false, false);
//
//        graphics.clip(bounds);
//        graphics.fillColor = KlighdConstants.WHITE;
//        graphics.fill(bounds);
//
//        // Draw all children on the diagram
//        root.children.forEach[ child |
//            if (child.ptolemyBounds.x != 2e20) {
//                graphics.strokeColor =
//                    if (child.markedAsComment)
//                        KlighdConstants.BLUE
//                    else
//                        KlighdConstants.BLACK;
//
//                graphics.draw(child.ptolemyBounds);
//            }
//        ];
//
//        // Find a proper file name
//        try {
//            val oStream = createOutputStream(root);
//            graphics.stream(oStream);
//            oStream.close();
//        } catch (IOException e) {
//            System.out.println("Unable to save debug output...");
//            e.printStackTrace();
//        }
//    }
//
//    private def OutputStream createOutputStream(KNode root) throws IOException {
//        val path = getDebugOutputPath();
//        new File(path).mkdirs();
//
//        val debugFileName = getDebugOutputFileName(root);
//        return new FileOutputStream(new File(path + File.separator + debugFileName + ".svg"));
//    }
//
//    private def String getDebugOutputPath() {
//        var path = System.getProperty("user.home");
//        if (path.endsWith(File.separator)) {
//            path += "tmp" + File.separator + "ptdebug";
//        } else {
//            path += File.separator + "tmp" + File.separator + "ptdebug";
//        }
//
//        return path;
//    }
//
//    private def String getDebugOutputFileName(KNode root) {
//        return Integer.toString(root.hashCode().bitwiseAnd((1 << (Integer.SIZE / 2)) - 1));
//    }

}