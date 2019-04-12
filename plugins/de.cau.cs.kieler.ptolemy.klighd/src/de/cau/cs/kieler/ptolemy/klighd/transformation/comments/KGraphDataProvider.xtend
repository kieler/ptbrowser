/*
 * KIELER - Kiel Integrated Environment for Layout Eclipse RichClient
 *
 * http://rtsys.informatik.uni-kiel.de/kieler
 * 
 * Copyright 2017 by
 * + Kiel University
 *   + Department of Computer Science
 *     + Real-Time and Embedded Systems Group
 * 
 * This code is provided under the terms of the Eclipse Public License (EPL).
 */
package de.cau.cs.kieler.ptolemy.klighd.transformation.comments

import com.google.common.collect.Lists
import com.google.inject.Guice
import com.google.inject.Inject
import de.cau.cs.kieler.klighd.kgraph.KNode
import de.cau.cs.kieler.klighd.kgraph.util.KGraphUtil
import de.cau.cs.kieler.ptolemy.klighd.transformation.KRenderingFigureProvider
import java.util.Collection
import java.util.List
import java.util.stream.Collectors
import org.eclipse.elk.core.comments.IDataProvider
import org.eclipse.elk.core.options.CoreOptions

/**
 * @author cds
 *
 */
class KGraphDataProvider implements IDataProvider<KNode, KNode> {
    
    @Inject extension KRenderingFigureProvider
    private val injector = Guice.createInjector();
    
    /** The graph we're providing data for. */
    private var KNode graph;
    
    
    /**
     * Makes the provider provide things in the given graph graph. Should be called right after creation.
     */
    public def KGraphDataProvider withGraph(KNode graph) {
        this.graph = graph;
        return this;
    }
    
    
    /////////////////////////////////////////////////////////////////////////////////////////////
    // IDataProvider
    
    override provideComments() {
        // Simply return all nodes marked as comments
        return graph.getChildren().stream()
            .filter[node | node.getProperty(CoreOptions.COMMENT_BOX)]
            .collect(Collectors.toList());
    }
    
    override provideTargets() {
        // Simply return all nodes marked as comments
        return graph.getChildren().stream()
            .filter[node | !node.getProperty(CoreOptions.COMMENT_BOX)]
            .collect(Collectors.toList());
    }
    
    override Collection<IDataProvider<KNode, KNode>> provideSubHierarchies() {
        // I'd have gone for a completely stream-based implementation, but Xtend had problems inferring the correct
        // types, for whatever reason...
        val List<IDataProvider<KNode, KNode>> result = Lists.newArrayList();
        graph.getChildren().stream()
                .filter[node | !node.getChildren().isEmpty()]
                .map[node | injector.getInstance(typeof(KGraphDataProvider)).withGraph(node)]
                .forEach(provider | result.add(provider));
        return result;
    }
    
    override attach(KNode comment, KNode target) {
        val edge = KGraphUtil.createInitializedEdge();
        edge.setSource(comment);
        edge.setTarget(target);
        
        edge.data += createCommentEdgeRendering(edge)
    }
    
}